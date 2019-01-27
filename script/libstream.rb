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
        give_up(' No IO command') unless iocmd
        super('stream')
        _attr_set(id, cfg[:version])
        update('dir' => '', 'cmd' => '', 'base64' => '')
        verbose { "Initiate [#{iocmd}]" }
        init_time2cmt
        ___init_par(cfg)
      end

      def snd(str, cid)
        return if str.to_s.empty?
        verbose { "Data Sending(#{cid})\n" + visible(str) }
        __reopen
        @f.write(str)
        __convert('snd', str, cid).cmt
      rescue Errno::EPIPE
        @f.close
        str_err('Stream: Send failed')
      end

      def rcv
        sleep @wait
        __reopen
        str = ___concat_rcv
        verbose { "Data Recieved(#{self['cmd']})\n" + visible(str) }
        __convert('rcv', str).cmt
      end

      private

      def __reopen
        ___open_strm if !@f || @f.closed?
      rescue SystemCallError
        str_err('Stream: Open failed')
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
        ___try_open
        Signal.trap(:INT, 'DEFAULT')
        verbose { 'Initiate Opened' }
        at_exit { ___close_strm }
        @post_open_proc.call
        # verbose { 'Stream Open successfully' }
        # Shut off from Ctrl-C Signal to the child process
        # Process.setpgid(@f.pid,@f.pid)
        self
      end

      def ___try_open
        @f = IO.popen(@iocmd, 'r+')
        3.times do
          Process.waitpid(@f.pid, Process::WNOHANG) &&
            str_err('Stream: Connection refused')
          sleep 0.1
        end
      end

      def ___close_strm
        return if @f.closed?
        verbose { 'Closing Stream' }
        Process.kill('TERM', @f.pid)
        Process.waitpid(@f.pid)
        @f.close
        verbose { @f.closed? ? 'Stream Closed' : 'Stream not Closed' }
      end

      def ___encode_base64(str)
        [str].pack('m').split("\n").join('')
      end

      # rcv sub methods
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
        str_err('Stream: No response')
      end

      def ___try_rcv(str)
        str << @f.sysread(4096)
        # verbose { "Binary Getting\n" + visible(str) }
      rescue EOFError
        # Jumped at quit
        @f.close
        str_err('Stream: Recv failed')
      end
    end
  end
end
