#!/usr/bin/env ruby
require 'libexedrv'
module CIAX
  # Frame Layer
  module Frm
    class Exe
      # Frame Exe module
      module Driver
        include CIAX::Exe::Driver

        def ext_local_driver
          super
          ___init_frame
          ___init_processor_ext
          ___init_processor_flush
          ___init_processor_reset
          self
        end

        private

        def ___init_frame
          @stat.ext_local_conv(@cfg)
        end

        def ___init_processor_ext
          @cobj.rem.ext.def_proc do |ent, src|
            @stat.conv(ent)
            @stat.flush if src != 'buffer'
          end
        end

        def ___init_processor_flush
          @cobj.get('flush').def_proc do
            @stat.frame.flush
            @stat.flush
            verbose { 'Flush Stream' }
          end
        end

        def ___init_processor_reset
          @cobj.get('reset').def_proc do
            @stat.frame.reset
            verbose { 'Reset Stream' }
          end
        end
      end
    end
  end
end
