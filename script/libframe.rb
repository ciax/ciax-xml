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
        # For stream log reading from stdin
        put(delete(:cmd), delete(:base64)) if key?(:cmd)
      end

      def get(id)
        val = super
        dec64(val) if val
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
          init_time2cmt(@stream)
          self
        end

        def ext_local_log
          @stream.ext_local_log
          self
        end

        def conv(ent)
          update(@stream.response(ent))
          verbose { 'Conversion Stream -> Frame' }
          cmt
        end

        def flush
          @stream.rcv
          cmt
        end

        def reset
          @stream.reset
          cmt
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        puts Frame.new(args.shift).mode(opt.host).path(args)
      end
    end
  end
end
