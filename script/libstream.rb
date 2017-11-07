#!/usr/bin/ruby
require 'libvarx'

# Structure
# {
#   @binary
#   time:Int
#   dir:(snd,rcv)
#   cmd:String
#   base64: encoded data
# }
module CIAX
  module Frm
    # Stream treats an individual round trip (send/recieve)
    #   communication which will be done sequentially
    class Stream < Varx
      attr_reader :binary
      attr_accessor :pre_open_proc, :post_open_proc
      def initialize(id, cfg)
        iocmd = type?(cfg, Config)[:iocmd]
        Msg.give_up(' No IO command') unless iocmd
        super('stream', id, cfg[:version])
        update('dir' => '', 'cmd' => '', 'base64' => '')
        verbose { "Initiate [#{iocmd}]" }
        init_time2cmt
        ___init_par(cfg)
        __reopen
      end

      def snd(str, cid)
        return if str.to_s.empty?
        verbose { "Data Sending(#{cid})\n" + visible(str) }
        __reopen
        @f.write(str)
        __convert('snd', str, cid).cmt
      rescue Errno::EPIPE
        @f.close
        com_err('send failed')
      end

      def rcv
        ___wait_rcv
        __reopen
        str = ___concat_rcv
        verbose { "Data Recieved(#{self['cmd']})\n" + visible(str) }
        __convert('rcv', str).cmt
      end

      private

      def __reopen(int = 0)
        ___open_strm if !@f || @f.closed?
      rescue SystemCallError
        int = ___open_fail(int)
        retry
      end

      def __convert(dir, data, cid = nil)
        @binary = data
        self['cmd'] = cid if cid
        update('dir' => dir, 'base64' => ___encode_base64(data))
      end

      def ___init_par(cfg)
        sp = type?(cfg, Config)[:stream]
        @iocmd = cfg[:iocmd].split(' ')
        @wait = (sp[:wait] || 0.01).to_f
        @timeout = (sp[:timeout] || 10).to_i
        @terminator = esc_code(sp[:terminator])
        @pre_open_proc = proc {}
        @post_open_proc = proc {}
      end

      def ___open_strm
        # SIGINT gets around the child process
        # verbose { 'Stream Opening' }
        @pre_open_proc.call
        Signal.trap(:INT, nil)
        @f = IO.popen(@iocmd, 'r+')
        Signal.trap(:INT, 'DEFAULT')
        verbose { 'Initiate Opened' }
        at_exit { ___close_strm }
        @post_open_proc.call
        # verbose { 'Stream Open successfully' }
        # Shut off from Ctrl-C Signal to the child process
        # Process.setpgid(@f.pid,@f.pid)
        self
      end

      def ___close_strm
        return if @f.closed?
        verbose { 'Closing Stream' }
        Process.kill('TERM', @f.pid)
        Process.waitpid(@f.pid)
        @f.close
        verbose { @f.closed? ? 'Stream Closed' : 'Stream not Closed' }
      end

      def ___open_fail(int)
        show_err
        Msg.str_err('Stream Open failed') if int > 2
        warning('Try to reopen')
        sleep int
        (int + 1) * 2
      end

      def ___encode_base64(str)
        [str].pack('m').split("\n").join('')
      end

      # rcv sub methods
      def ___wait_rcv
        # verbose { "Wait to Recieve #{@wait} sec" }
        sleep @wait
        # verbose { 'Wait for Recieving' }
      end

      def ___concat_rcv(str = '')
        20.times do
          ___select_io
          ___try_rcv(str)
          break if !@terminator || /#{@terminator}/ =~ str
          verbose { 'Recieved incomplete data, retry' }
        end
        str
      end

      def ___select_io
        return if IO.select([@f], nil, nil, @timeout)
        Msg.com_err('Stream:No response')
      end

      def ___try_rcv(str)
        str << @f.sysread(4096)
        # verbose { "Binary Getting\n" + visible(str) }
      rescue EOFError
        # Jumped at quit
        @f.close
        com_err('recv failed')
      end
    end
  end
end
