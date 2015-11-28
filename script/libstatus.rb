#!/usr/bin/ruby
require 'libdatax'

module CIAX
  # Application Layer
  module App
    # Status Data
    class Status < DataH
      # @ last*
      attr_reader :last
      def initialize(init_struct = {})
        super('status', init_struct)
        @last = {}
        @updated = now_msec
        @lastsave = now_msec
      end

      def setdbi(db)
        super
        if @data.empty?
          @adbs = @dbi[:status][:index]
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
      require 'libinsdb'
      OPT.parse('h:')
      stat = Status.new
      begin
        dbi = Ins::Db.new.get(ARGV.shift)
        stat.setdbi(dbi)
        if OPT.host
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
