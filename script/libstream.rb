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
        @cls_color = 9
        update('dir' => '', 'cmd' => '', 'base64' => '')
        verbose { "Initialize [#{iocmd}]" }
        _init_par(cfg)
        puts cfg.path
        reopen
      end

      def snd(str, cid)
        return if str.to_s.empty?
        verbose { "Sending #{str.size} byte on #{cid}" }
        verbose { "Data Sending\n" + visible(str) }
        reopen
        @f.write(str)
        convert('snd', str, cid)
        self
      rescue Errno::EPIPE
        @f.close
        raise(CommError)
      ensure
        post_upd
      end

      def rcv
        verbose { "Wait to Recieve #{@wait} sec" }
        sleep @wait
        verbose { 'Wait for Recieving' }
        reopen
        str = ''
        20.times do
          try_rcv(str)
          break if ! @terminator || /#{@terminator}/ =~ str
          verbose { 'Recieved incomplete data, retry' }
        end
        verbose { "Recieved #{str.size} byte on #{self['cmd']}" }
        convert('rcv', str)
        verbose { "Data Recieved(#{time_id})\n" + visible(str) }
        self
      ensure
        post_upd
      end

      def reopen
        int = 0
        begin
          open_strm if !@f || @f.closed?
        rescue SystemCallError
          warning($ERROR_INFO)
          Msg.str_err('Stream Open failed') if int > 2
          warning('Try to reopen')
          sleep int
          int = (int + 1) * 2
          retry
        end
      end

      private

      def _init_par(cfg)
        sp = type?(cfg, Config)[:stream]
        @iocmd = cfg[:iocmd].split(' ')
        @wait = (sp[:wait] || 0.01).to_f
        @timeout = sp[:timeout] || 10
        @terminator = esc_code(sp[:terminator])
        @pre_open_proc = proc {}
        @post_open_proc = proc {}
      end

      def open_strm
        # SIGINT gets around the child process
        verbose { 'Stream Opening' }
        @pre_open_proc.call
        Signal.trap(:INT, nil)
        @f = IO.popen(@iocmd, 'r+')
        Signal.trap(:INT, 'DEFAULT')
        at_exit { close_strm }
        @post_open_proc.call
        verbose { 'Stream Open successfully' }
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

      def try_rcv(str)
        if IO.select([@f], nil, nil, @timeout)
          begin
            str << @f.sysread(4096)
            verbose { "Binary Getting\n" + visible(str) }
          rescue EOFError
            # Jumped at quit
            @f.close
            raise(CommError)
          end
        else
          Msg.com_err('Stream:No response')
        end
      end

      def convert(dir, data, cid = nil)
        pre_upd
        @binary = data
        update('dir' => dir, 'base64' => encode(data))
        self['cmd'] = cid if cid
        self
      end

      def encode(str)
        [str].pack('m').split("\n").join('')
      end
    end
  end
end
