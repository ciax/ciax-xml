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
          ___init_processor_flush
          ___init_processor_reset
          self
        end

        private

        def ___init_stream
          @stat.ext_local_conv
          @stream = Stream::Driver.new(@id, @cfg)
          @frame.ext_local_conv(@stream).ext_file.ext_save
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

        def ___init_processor_flush
          @cobj.get('flush').def_proc do
            @stream.rcv
            verbose { 'Flush Stream' }
          end
        end

        def ___init_processor_reset
          @cobj.get('reset').def_proc do
            @stream.reset
            verbose { 'Reset Stream' }
          end
        end
      end
    end
  end
end
