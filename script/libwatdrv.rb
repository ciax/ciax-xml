#!/usr/bin/ruby
module CIAX
  # Watch Layer
  module Wat
    class Exe
      # Event Driven
      module Driver
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_local_driver
          @stat.ext_local_file.auto_save
          # @stat[:int] is overwritten by initial loading
          @sub.batch_interrupt = @stat.get(:int)
          @stat.ext_local_log if @cfg[:opt].log?
          ___init_upd_processor
          ___init_exe_processor
          self
        end

        private

        def ___init_upd_processor
          @stat.cmt_procs << proc do |ev|
            ev.get(:exec).each do |src, pri, args|
              verbose { "Propagate Exec:#{args} from [#{src}] by [#{pri}]" }
              @sub.exe(args, src, pri)
              sleep ev.interval
            end.clear
          end
        end

        def ___init_exe_processor
          @th_auto = ___init_auto_thread unless @cfg[:cmd_line_mode]
          @sub.post_exe_procs << proc do
            @sv_stat.set_flg(:auto, @th_auto && @th_auto.alive?)
          end
        end

        def ___init_auto_thread
          Threadx::Loop.new('Regular', 'wat', @id) do
            @stat.auto_exec unless @sv_stat.up?(:comerr)
            sleep 10
          end
        end
      end
    end
  end
end
