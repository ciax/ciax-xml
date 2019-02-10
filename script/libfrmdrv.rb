#!/usr/bin/env ruby
module CIAX
  # Frame Layer
  module Frm
    class Exe
      # Frame Exe module
      module Driver
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_local_driver
          ___init_frame
          ___init_processor_ext
          ___init_processor_save
          ___init_processor_load
          ___init_processor_flush
          ___init_log_mode
          self
        end

        private

        def ___init_frame
          @frame.ext_local_conv(@cfg).ext_save
          @stat.ext_local_conv(@frame)
        end

        def ___init_processor_ext
          @cobj.rem.ext.def_proc do |ent, src|
            @frame.conv(ent)
            @stat.conv(ent)
            @stat.flush if src != 'buffer'
          end
        end

        def ___init_processor_save
          @cobj.get('save').def_proc do |ent|
            @stat.save_partial(ent.par[0].split(','), ent.par[1])
            verbose { "Saving [#{ent.par[0]}]" }
          end
        end

        def ___init_processor_load
          @cobj.get('load').def_proc do |ent|
            @stat.load_partial(ent.par[0] || '')
            @stat.flush
            verbose { "Loading [#{ent.par[0]}]" }
          end
        end

        def ___init_processor_flush
          @cobj.get('flush').def_proc do
            @frame.reset
            @stat.flush
            verbose { 'Flush Stream' }
          end
        end

        def ___init_log_mode
          return unless @opt.drv?
          @frame.ext_local_log
          @cobj.rem.ext_input_log
        end
      end
    end
  end
end
