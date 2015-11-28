#!/usr/bin/ruby
require 'libdatax'
require 'libinsdb'

module CIAX
  # Application Layer
  module App
    # Status Data
    # All elements of @data are String
    class Status < DataH
      # @ last*
      attr_reader :last
      def initialize(id = nil, db = Ins::Db.new)
        super('status')
        @last = {}
        @updated = now_msec
        @lastsave = now_msec
        @adb = type?(db, CIAX::Db)
        id = read[:id] unless STDIN.tty?
p self
p @data
setdbi(@adb.get(id))
      end

      def setdbi(db)
        super
        @adbs = @dbi[:status][:index]
        if @data.empty?
          @data.update(@adbs.skeleton)
        end
        self
      end

      def change?(k)
        verbose do
          "Compare(#{k}) current=[#{@data[k]}]"\
          " vs last=[#{@last[k]}]"
        end
        @data[k] != @last[k]
      end

      def update?
        self[:time] > @updated
      end

      def refresh
        verbose { 'Status Refreshed' }
        @last.update(@data)
        @updated = self[:time]
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('h:')
      begin
        stat = Status.new(ARGV.shift)
puts stat
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
