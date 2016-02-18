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
      def initialize(dbi = nil)
        super('status')
        @last = {}
        @updated = now_msec
        @lastsave = now_msec
        _setdbi(dbi, Ins::Db)
        # exclude alias from index
        @adbs = @dbi[:status][:index].select{ |k,v| v[:ref] }
        self[:data] = Hashx[@adbs].skeleton unless self[:data]
      end

      def change?(k)
        verbose do
          "Compare(#{k}) current=[#{self[:data][k]}]"\
          " vs last=[#{@last[k]}]"
        end
        self[:data][k] != @last[k]
      end

      def update?
        self[:time] > @updated
      end

      def refresh
        verbose { 'Status Refreshed' }
        @last.update(self[:data])
        @updated = self[:time]
        self
      end

      def str_update(str)
        str.split(',').each do |tkn|
          self[:data].rep(*tkn.split('='))
        end
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('h:')
      begin
        stat = Status.new
        if OPT[:h]
          stat.ext_http(OPT.host)
        else
          stat.ext_file
        end
        puts stat
      rescue InvalidID
        OPT.usage '(opt) [id]'
      end
    end
  end
end
