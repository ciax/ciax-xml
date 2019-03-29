#!/usr/bin/env ruby
require 'libvarx'
require 'libconf'
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
      attr_reader :base64
      def initialize(id, cfg)
        iocmd = type?(cfg, Config)[:iocmd] || give_up(' No IO command')
        super('stream')
        @sv_stat = cfg[:sv_stat]
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
        __error('Stream: Send failed')
      end

      def rcv
        sleep @wait
        __reopen
        str = ___concat_rcv
        verbose { "Data Recieved(#{self['cmd']})\n" + visible(str) }
        __convert('rcv', str).cmt
      end

      def reset
        ___close_strm
        cmt
      end

      def response(ent)
        type?(ent, Config)
        return {} unless snd(ent[:frame], ent.id) && ent.key?(:response) && rcv
        { ent.id => @base64 }
      end

      private

      def __reopen
        ___open_strm if !@f || @f.closed?
      rescue SystemCallError
        __error('Stream: Open failed')
      end

      def __convert(dir, data, cid = nil)
        @base64 = enc64(data)
        self['cmd'] = cid if cid
        update('dir' => dir, 'base64' => @base64)
      end

      def ___init_par(cfg)
        sp = type?(cfg, Config)[:stream]
        @iocmd = cfg[:iocmd].split(' ').push(pgroup: 0)
        @wait = (sp[:wait] || 0.01).to_f
        @timeout = (sp[:timeout] || 10).to_i
        @terminator = esc_code(sp[:terminator])
      end

      def ___open_strm
        # SIGINT gets around the child process
        # verbose { 'Stream Opening' }
        # Signal.trap(:INT, nil)
        ___try_open
        # Signal.trap(:INT, 'DEFAULT')
        verbose { 'Initiate Opened' }
        at_exit { ___close_strm }
        # verbose { 'Stream Open successfully' }
        # Shut off from Ctrl-C Signal to the child process
        # Process.setpgid(@f.pid,@f.pid)
        self
      end

      def ___try_open
        @sv_stat.dw(:ioerr).dw(:comerr) if @sv_stat
        @f = IO.popen(@iocmd, 'r+')
        3.times do
          Process.waitpid(@f.pid, Process::WNOHANG) &&
            __error('Stream: Connection refused')
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
        __error('Stream: Timeout: No response')
      end

      def ___try_rcv(str)
        str << @f.sysread(4096)
        # verbose { "Binary Getting\n" + visible(str) }
      rescue EOFError
        # Jumped at quit
        __error('Stream: Recv failed')
      end

      def __error(str)
        @f.close if @f
        @sv_stat.up(:ioerr) if @sv_stat
        str_err(str)
      end
    end
  end
end
