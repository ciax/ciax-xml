#!/usr/bin/env ruby
require 'libexedrv'
module CIAX
  # Frame Layer
  module Frm
    class Exe
      # Frame Exe module
      module Driver
        include CIAX::Exe::Driver

        def ext_driver
          if @frame
            ___init_frame
            ___init_processor_ext
            ___init_processor_int
          end
          @sv_stat.ext_local.ext_file.ext_save.ext_log
          super
        end

        private

        def _init_log_mode
          return unless super
          @frame.ext_log if @frame
        end

        def ___init_frame
          @stat.ext_conv
          @frame.ext_local.ext_conv(@cfg).ext_save
        end

        def ___init_processor_ext
          @cobj.rem.ext.def_proc do |ent|
            # This corresponds the propagation
            next unless @frame.conv(ent)
            @stat.conv(ent)
            # Frm: Update after each single command finish
            #   flush => clear [:comerr]
            @stat.flush if ent[:src] != 'buffer'
          end
        end

        def ___init_processor_int
          _set_def_proc('flush') { @frame.flush }
          _set_def_proc('reset') { @frame.reset }
        end
      end
    end
  end
end
