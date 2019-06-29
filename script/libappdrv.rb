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
        def ext_driver
          super
          return self unless @sub_exe
          @stat.ext_sym(@cfg[:sdb]).ext_conv
          ___init_buffer
          self
        end

        private

        def _init_log_mode
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
          buf = Buffer.new(@sv_stat, @sub_exe.cobj) do |args, src|
            verbose { cfmt('Processing App to Buffer %p', args) }
            @sub_exe.exe(args, src)
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
          _set_def_proc('reset') { @sv_stat.reset }
          _set_def_proc('interrupt') do |ent|
            @batch_interrupt.each do |args|
              verbose { "Issuing:#{args} for Interrupt" }
              buf.send(@cobj.set_cmd(args.dup), 0)
            end
            warning('Interrupt%p from %s', @batch_interrupt, ent[:src])
          end
        end

        # App: Sending a general App command (Frm batch)
        def ___init_proc_ext(buf)
          @cobj.rem.ext.def_proc do |ent|
            verbose { _exe_text(ent.id, ent[:src], ent[:pri]) }
            buf.send(ent, ent[:pri])
          end
        end
      end
    end
  end
end
