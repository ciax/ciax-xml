#!/usr/bin/env ruby
require 'libbuffer'
require 'libexedrv'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    class Exe
      # Driver module
      module Driver
        include CIAX::Exe::Driver

        # type of usage: shell/command line
        # type of semantics: execution/test
        def ext_local_driver
          super
          return self unless @sub
          @stat.ext_conv
          @stat.ext_sym(@cfg[:sdb])
          ___init_buffer
          self
        end

        private

        def ___init_log_mode
          super && @stat.ext_sqlog
        end

        # Process of command execution:
        #  Main: Recieve App command with validation
        #  Main: Set :busy flag in Server status
        #  Main: Send command to queue of Buffer thread (Async)
        #  Main: Send back App response with msg 'ISSUED' in Server Status
        #    Buffer: Recieve the command from queue
        #    Buffer: Break up to Frm commands (Batch)
        #    Buffer: Reorder by priority and set command to outbuffer
        #      Batch: Pick up the command from outbuffer by priority
        #      Batch: Execute single Frm command
        #      Batch: Get Frm command response
        #      Batch: Update Field by Frm response
        #      Batch: Repeat until outbuffer is empty
        def ___init_buffer
          buf = Buffer.new(@sv_stat, @sub.cobj) do |args, src|
            verbose { cfmt('Processing App to Buffer %S', args) }
            @sub.exe(args, src)
          end
          ___init_proc_int(buf)
          ___init_proc_ext(buf)
          # @stat file output should be done before :busy flag is reset
          @stat.propagation(buf)
          # Start buffer server thread
          buf.server
        end

        # App: Sendign a first priority command (interrupt)
        def ___init_proc_int(buf)
          @cobj.get('interrupt').def_proc do |_ent, src|
            @batch_interrupt.each do |args|
              verbose { "Issuing:#{args} for Interrupt" }
              buf.send(@cobj.set_cmd(args.dup), 0)
            end
            warning('Interrupt%S from %s', @batch_interrupt, src)
          end
        end

        # App: Sending a general App command (Frm batch)
        def ___init_proc_ext(buf)
          @cobj.rem.ext.def_proc do |ent, src, pri|
            verbose { _exe_text(ent.id, src, pri) }
            buf.send(ent, pri)
          end
        end
      end
    end
  end
end
