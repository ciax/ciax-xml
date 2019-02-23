#!/usr/bin/env ruby
require 'libstatx'
require 'libinsdb'

module CIAX
  # Application Layer
  module App
    # Status Data
    # All elements of @data are String
    class Status < Statx
      include Dic
      # dbi can be Ins::Db or ID for new Db
      def initialize(dbi = nil)
        super('status', dbi, Ins::Db)
        ___init_dbs
        # cmt_procs
        # 1. time setting
        # 2. convert
        # 3. sym
        # 4. save
        @cmt_procs << proc { verbose { "Saved #{self[:id]}:timing" } }
      end

      # set vars by csv
      def str_update(str)
        str.split(',').each do |tkn|
          @dic.repl(*tkn.split('='))
        end
        self
      end

      # Structure is Hashx{ data:{ key,val ..} }
      def pick(keyary, atrb = {})
        Hashx.new(atrb).update(data: @dic.pick(keyary))
      end

      def jread(str = nil)
        res = super
        res[:data] = Hashx.new(res[:data])
        res
      end

      private

      def ___init_dbs
        # exclude alias from index
        @adbs = @dbi[:status]
        @adbsi = @adbs[:index].reject { |_k, v| v[:ref] }
        ext_dic(:data) { Hashx.new(@adbsi).skeleton }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id]', options: 'h') do |opt, args|
        stat = Status.new(args.shift)
        if opt.host
          stat.ext_remote(opt.host)
        else
          stat.ext_local.load
        end
        puts stat
      end
    end
  end
end
