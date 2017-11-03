#!/usr/bin/ruby
require 'libbuffer'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    class Exe
      # Drv module
      module Drv
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        # type of usage: shell/command line
        # type of semantics: execution/test
        def ext_local_driver
          @stat.ext_local_rsp(@sub.stat)
          @stat.ext_local_sym(@cfg[:sdb]).ext_local_file.auto_save
          @buf = init_buf
          _init_log_mode
          _init_drv_save
          _init_drv_load
          self
        end

        private

        def _init_log_mode
          return unless @cfg[:opt].log?
          @stat.ext_local_log.ext_local_sqlog
          @cobj.rem.ext_input_log
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
        def init_buf
          buf = Buffer.new(@sv_stat)
          _init_proc_int_(buf)
          _init_proc_ext_(buf)
          _init_proc_buf_(buf)
          _init_proc_sub_
          # Start buffer server thread
          buf.server
        end

        # App: Sendign a first priority command (interrupt)
        def _init_proc_int_(buf)
          @cobj.get('interrupt').def_proc do |_ent, src|
            @batch_interrupt.each do |args|
              verbose { "Issuing:#{args} for Interrupt" }
              buf.send(@cobj.set_cmd(args), 0)
            end
            warning("Interrupt(#{@batch_interrupt}) from #{src}")
          end
        end

        def _init_drv_save
          @cobj.get('save').def_proc do |ent|
            @stat.save_key(ent.par[0].split(','), ent.par[1])
            verbose { "Save [#{ent.par[0]}]" }
          end
        end

        def _init_drv_load
          @cobj.get('load').def_proc do |ent|
            @stat.load(ent.par[0] || '')
            verbose { "Load [#{ent.par[0]}]" }
          end
        end

        # App: Sending a general App command (Frm batch)
        def _init_proc_ext_(buf)
          @cobj.rem.ext.def_proc do |ent, src, pri|
            verbose { "Issuing:[#{ent.id}] from #{src} with priority #{pri}" }
            buf.send(ent, pri)
          end
        end

        def _init_proc_buf_(buf)
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

        # Field: Update after each Batch Frm command finish
        def _init_proc_sub_
          @sub.stat.flush_procs << proc do
            verbose { 'Propagate Field#flush -> Status#cmt' }
            @stat.cmt
          end
        end
      end
    end
  end
end
