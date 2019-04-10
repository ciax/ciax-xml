#!/usr/bin/env ruby
require 'libwatact'
module CIAX
  # Watch Layer
  module Wat
    class Exe
      # Event Driven
      module Driver
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_driver
          @stat.ext_conv
          # @stat[:int] is overwritten by initial loading
          @sub.batch_interrupt = @stat.get(:int)
          ___init_cmt_procs
          ___init_exe_processor
          @stat.ext_log if @opt.drv?
          self
        end

        private

        def ___init_cmt_procs
          act = Action.new(@stat, @sv_stat, @sub)
          @stat.cmt_procs.append(self, :action, 1) { act.action }
        end

        def ___init_exe_processor
          @th_auto = ___init_auto_thread unless @cfg[:cmd_line_mode]
          @sub.post_exe_procs << proc do
            @sv_stat.set_flg(:auto, @th_auto && @th_auto.alive?)
          end
        end

        def ___init_auto_thread
          Threadx::Loop.new('Auto', 'wat', @id) do
            @stat.auto_exec unless @sv_stat.up?(:comerr)
            sleep 10
          end
        end
      end
    end
  end
end
