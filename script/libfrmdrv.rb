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
            @stat.frame.reset
            @stat.flush
            verbose { 'Flush Stream' }
          end
        end
      end
    end
  end
end
