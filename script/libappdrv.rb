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
          @stat.ext_local_conv
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
          buf = Buffer.new(@sv_stat, @sub.cobj)
          ___init_proc_int(buf)
          ___init_proc_ext(buf)
          ___init_proc_buf(buf)
          # Start buffer server thread
          buf.server
        end

        # App: Sendign a first priority command (interrupt)
        def ___init_proc_int(buf)
          @cobj.get('interrupt').def_proc do |_ent, src|
            @batch_interrupt.each do |args|
              verbose { "Issuing:#{args} for Interrupt" }
              buf.send(@cobj.set_cmd(args), 0)
            end
            warning("Interrupt(#{@batch_interrupt}) from #{src}")
          end
        end

        # App: Sending a general App command (Frm batch)
        def ___init_proc_ext(buf)
          @cobj.rem.ext.def_proc do |ent, src, pri|
            verbose { "Issuing:[#{ent.id}] from #{src} with priority #{pri}" }
            buf.send(ent, pri)
          end
        end

        def ___init_proc_buf(buf)
          # Frm: Execute single command
          buf.recv_proc = proc do |args, src|
            verbose { "Processing App to Buffer #{args}" }
            @sub.exe(args, src)
          end
          # Frm: Update after each single command finish
          # @stat file output should be done before :busy flag is reset
          buf.flush_proc = proc do
            verbose { 'Propagate Buffer#flush -> Field#flush' }
            @sub.stat.flush
          end
        end
      end
    end
  end
end
