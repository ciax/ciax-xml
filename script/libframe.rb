#!/usr/bin/env ruby
require 'libstatx'
require 'libdic'
require 'libdevdb'

module CIAX
  # Frame Layer
  module Stream
    # Response Frame DB
    class Frame < Statx
      include Dic
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
      # Local mode
      module Local
        include Varx::Local
        def ext_conv(cfg)
          extend(Conv).ext_conv(cfg)
        end
      end

      # Converting module
      module Conv
        def self.extended(obj)
          Msg.type?(obj, Frame)
        end

        def ext_conv(cfg)
          @stream = Stream::Driver.new(@id, cfg)
          self
        end

        # Parameter could be Stream::Driver or empty Hash
        #  Stream::Driver will commit twice(snd,rcv) par one commit here
        #  So no propagation with it except time update
        def conv(ent)
          res = @stream.response(ent)
          return unless res
          # Time update from Stream
          time_upd(res)
          cid = res['cmd']
          _dic.update(cid => res['base64'])
          verbose { _conv_text('Stream -> Frame', cid, time_id) }
          self
        end

        # Indivisual commands
        def flush
          @stream.rcv
          verbose { 'Flush Stream' }
        end

        def reset
          @stream.reset
          verbose { 'Reset Stream' }
        end
      end
    end
    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        puts Frame.new(args).cmode(opt.host)
      end
    end
  end
end
