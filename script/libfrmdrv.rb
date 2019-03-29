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
          @stat.ext_local_conv(@cfg)
          @stream = Stream::Driver.new(@id, @cfg)
          @frame.init_time2cmt(@stream)
        end

        def ___init_processor_ext
          @cobj.rem.ext.def_proc do |ent, src|
            @frame.input(@stream.response(ent))
            @stat.conv(ent)
            @stat.flush unless src == 'buffer'
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
