#!/usr/bin/env ruby
require 'libexedrv'
require 'libstream'
module CIAX
  # Frame Layer
  module Frm
    class Exe
      # Frame Exe module
      module Driver
        include CIAX::Exe::Driver

        def ext_local_driver
          super
          ___init_stream
          ___init_processor_ext
          ___init_processor_int
          self
        end

        private

        def ___init_stream
          @stat.ext_local_conv
          @frame.ext_local_conv(@cfg).ext_file.ext_save
        end

        def ___init_processor_ext
          @cobj.rem.ext.def_proc do |ent, src|
            # This corresponds the propagation
            next unless @frame.conv(ent)
            @stat.conv(ent)
            # Frm: Update after each single command finish
            #   flush => clear [:comerr]
            @stat.flush if src != 'buffer'
          end
        end

        def ___init_processor_int
          @cobj.get('flush').def_proc { @frame.flush }
          @cobj.get('reset').def_proc { @frame.reset }
        end
      end
    end
  end
end
