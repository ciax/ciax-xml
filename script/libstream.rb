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
        _init_par(cfg)
        reopen
      end

      def snd(str, cid)
        return if str.to_s.empty?
        verbose { "Data Sending(#{cid})\n" + visible(str) }
        reopen
        @f.write(str)
        convert('snd', str, cid).cmt
      rescue Errno::EPIPE
        @f.close
        com_err('send failed')
      end

      def rcv
        _wait_rcv
        reopen
        str = _concat_rcv
        verbose { "Data Recieved(#{self['cmd']})\n" + visible(str) }
        convert('rcv', str).cmt
      end

      def reopen(int = 0)
        open_strm if !@f || @f.closed?
      rescue SystemCallError
        int = _open_fail(int)
        retry
      end

      private

      def convert(dir, data, cid = nil)
        @binary = data
        self['cmd'] = cid if cid
        update('dir' => dir, 'base64' => encode(data))
      end

      def _init_par(cfg)
        sp = type?(cfg, Config)[:stream]
        @iocmd = cfg[:iocmd].split(' ')
        @wait = (sp[:wait] || 0.01).to_f
        @timeout = (sp[:timeout] || 10).to_i
        @terminator = esc_code(sp[:terminator])
        @pre_open_proc = proc {}
        @post_open_proc = proc {}
      end

      def open_strm
        # SIGINT gets around the child process
        # verbose { 'Stream Opening' }
        @pre_open_proc.call
        Signal.trap(:INT, nil)
        @f = IO.popen(@iocmd, 'r+')
        Signal.trap(:INT, 'DEFAULT')
        verbose { 'Initiate Opened' }
        at_exit { close_strm }
        @post_open_proc.call
        # verbose { 'Stream Open successfully' }
        # Shut off from Ctrl-C Signal to the child process
        # Process.setpgid(@f.pid,@f.pid)
        self
      end

      def close_strm
        return if @f.closed?
        verbose { 'Closing Stream' }
        Process.kill('INT', @f.pid)
        Process.waitpid(@f.pid)
        @f.close
        verbose { @f.closed? ? 'Stream Closed' : 'Stream not Closed' }
      end

      def _open_fail(int)
        warning($ERROR_INFO)
        Msg.str_err('Stream Open failed') if int > 2
        warning('Try to reopen')
        sleep int
        (int + 1) * 2
      end

      def encode(str)
        [str].pack('m').split("\n").join('')
      end

      # rcv sub methods
      def _wait_rcv
        # verbose { "Wait to Recieve #{@wait} sec" }
        sleep @wait
        # verbose { 'Wait for Recieving' }
      end

      def _concat_rcv(str = '')
        20.times do
          _select_io
          _try_rcv(str)
          break if !@terminator || /#{@terminator}/ =~ str
          verbose { 'Recieved incomplete data, retry' }
        end
        str
      end

      def _select_io
        return if IO.select([@f], nil, nil, @timeout)
        Msg.com_err('Stream:No response')
      end

      def _try_rcv(str)
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
