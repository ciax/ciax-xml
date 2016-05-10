#!/usr/bin/ruby
require 'libvarx'
require 'libinsdb'

module CIAX
  # Application Layer
  module App
    # Status Data
    # All elements of @data are String
    class Status < Varx
      # @ last*
      attr_reader :last
      # dbi can be Ins::Db or ID for new Db
      def initialize(dbi = nil)
        super('status')
        @last = {}
        @updated = now_msec
        @lastsave = now_msec
        _setdbi(dbi, Ins::Db)
        _init_sdb
        @cmt_procs << proc { verbose { "Saved #{self[:id]}:timing" } }
      end

      def change?(k)
        verbose do
          "Compare(#{k}) current=[#{self[:data][k]}]"\
          " vs last=[#{@last[k]}]"
        end
        self[:data][k] != @last[k]
      end

      def updated?
        self[:time] > @updated
      end

      def refresh
        verbose { 'Status Refreshed' }
        @last.update(self[:data])
        @updated = self[:time]
        self
      end

      # set vars by csv
      def str_update(str)
        str.split(',').each do |tkn|
          self[:data].repl(*tkn.split('='))
        end
        self
      end

      # Structure is Hashx{ data:{ key,val ..} }
      def pick(keylist, atrb = {})
        Hashx.new(atrb).update(data: self[:data].pick(keylist))
      end

      def ext_local_file
        super.load
      end

      private

      def _init_sdb
        # exclude alias from index
        @adbs = @dbi[:status][:index].reject { |_k, v| v[:ref] }
        self[:data] = Hashx.new(@adbs).skeleton unless self[:data]
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id]', 'h:') do |opt|
        stat = Status.new
        if opt[:h]
          stat.ext_http(opt.host)
        else
          stat.ext_local_file
        end
        puts stat
      end
    end
  end
end
