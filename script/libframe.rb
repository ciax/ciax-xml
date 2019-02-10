#!/usr/bin/env ruby
require 'libvarx'
require 'libstream'

module CIAX
  # Frame Layer
  module Frm
    # Response Frame DB
    class Frame < Varx
      attr_reader :rid
      def initialize(id = nil)
        super('frame')
        _attr_set(id) if id
        self[:frames] = Hashx.new
      end

      def get(key)
        self[:frames][key]
      end

      def put(key, val)
        self[:frames][key] = val
        self
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
          propagation(@stream)
          self
        end

        def ext_local_log
          @stream.ext_local_log
          self
        end

        def conv(ent)
          @stream.snd(ent[:frame], ent.id)
          put(ent.id, @stream.rcv.binary) if ent.key?(:response)
          verbose { "Propagate Stream#rcv -> Frame#conv #{to_v}" }
          self
        rescue StreamError
          @sv_stat.up(:ioerr)
          raise
        ensure
          cmt
        end

        def reset
          @stream.rcv
          self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id]', options: 'h') do |opt, args|
        fld = Frame.new(args.shift)
        if opt.host
          fld.ext_remote(opt.host)
        else
          fld.ext_local.load
        end
        puts fld
      end
    end
  end
end
