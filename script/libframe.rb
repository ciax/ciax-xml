#!/usr/bin/env ruby
require 'libstatx'
require 'libdevdb'
require 'libstream'

module CIAX
  # Frame Layer
  module Frm
    # Response Frame DB
    class Frame < Statx
      include Dic
      attr_reader :rid
      def initialize(dbi = nil)
        super('frame', dbi, Dev::Db)
        ext_dic(:data) { Hashx.new(@dbi[:response][:index]).skeleton }
      end

      def get(id)
        dec64(super)
      end

      def ext_local_conv(cfg)
        extend(Conv).ext_local_conv(cfg)
      end
      # Convert module
      module Conv
        def self.extended(obj)
          Msg.type?(obj, Frame)
        end

        def ext_local_conv(cfg)
          @stream = Stream.new(@id, cfg)
          @sv_stat = type?(cfg[:sv_stat], Prompt)
          @stream.pre_open_proc = proc do
            @sv_stat.dw(:ioerr)
            @sv_stat.dw(:comerr)
          end
          init_time2cmt(@stream)
          self
        end

        def ext_local_log
          @stream.ext_local_log
          self
        end

        def conv(ent)
          @stream.snd(ent[:frame], ent.id)
          put(ent.id, @stream.rcv.base64) if ent.key?(:response)
          verbose { 'Conversion Stream -> Frame' }
          self
        rescue StreamError
          @sv_stat.up(:ioerr)
          raise
        end

        def reset
          @stream.rcv
          self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id]', options: 'h') do |opt, args|
        puts Frame.new(args.shift).mode(opt.host).path(args)
      end
    end
  end
end
