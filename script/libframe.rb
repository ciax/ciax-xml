#!/usr/bin/env ruby
require 'libstatx'
require 'libdic'
require 'libdevdb'
require 'libstream'

module CIAX
  # Frame Layer
  module Stream
    # Response Frame DB
    class Frame < Statx
      include Dic
      def initialize(dbi = nil)
        super('frame', dbi, Dev::Db)
        args_err('No response DB') unless @dbi.key?(:response)
        @rdb = @dbi[:response][:index]
        ext_dic(:data) { Hashx.new(@rdb).skeleton }
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

        def ext_log
          warning('Do nothing')
          self
        end
      end

      # Converting module
      module Conv
        def self.extended(obj)
          Msg.type?(obj, Frame)
        end

        def ext_conv(cfg)
          @cache = {}
          @stream = Stream::Driver.new(@id, cfg)
          propagation(@stream)
          self
        end

        def ext_log
          @stream.ext_local.ext_log
          self
        end

        # Parameter could be Stream::Driver or empty Hash
        #  Stream::Driver will commit twice(snd,rcv) par one commit here
        #  So no propagation with it except time update
        def conv(ent)
          res = @stream.response(ent)
          return unless res
          cid = ___index_cid(res['cmd'])
          _dic.update(cid => res['base64'])
          # Time update from Stream
          time_upd
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

        private

        # Modify cid having only index (distinct from free number)
        def ___index_cid(cid)
          return cid if cid !~ /:/
          argv = cid.split(':')
          argv[0..___idx_num(argv)].join(':')
        end

        def ___idx_num(argv)
          id = argv.first
          return @cache[id] if @cache.key?(id)
          @cache[id] = ___get_idx(id).select { |s| s =~ /\$/ }.size
        end

        def ___get_idx(id)
          rid = @dbi[:command][:index][id][:response]
          return [] unless (bary = @rdb[rid][:body])
          pars = bary.select { |h| h[:type] == 'assign' }.first || {}
          pars[:index] || []
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
