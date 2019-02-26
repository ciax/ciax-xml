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
      attr_reader :rid, :dic
      def initialize(dbi = nil)
        super('frame', dbi, Dev::Db)
        ext_dic(:data) { Hashx.new(@dbi[:response][:index]).skeleton }
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
          put(ent.id, @stream.rcv.binary) if ent.key?(:response)
          verbose { 'Conversion Stream -> Frame' + to_v }
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
        frm = Frame.new(args.shift)
        if opt.host
          frm.ext_remote(opt.host)
        else
          frm.ext_local
        end
        puts frm.path(args)
      end
    end
  end
end
