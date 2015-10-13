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

      def change?(id)
        verbose do
          "Compare(#{id}) current=[#{@data[id]}]"\
          " vs last=[#{@last[id]}]"
        end
        @data[id] != @last[id]
      end

      def update?
        self['time'] > @updated
      end

      def refresh
        verbose { 'Status Updated' }
        @last.update(@data)
        @updated = self['time']
        self
      end
    end

    # Loading feature
    module JLoad
      # @< (db),(base),(prefix)
      # @< (last)
      # @ lastsave
      include CIAX::JLoad
      def self.extended(obj)
        Msg.type?(obj, Status)
      end

      def save(tag = nil)
        time = self['time']
        if time > @lastsave
          super
          @lastsave = time
        else
          verbose { "Skip Save for #{time}" }
        end
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
          stat.ext_save.ext_load
        end
        puts STDOUT.tty? ? stat : stat.to_j
      rescue InvalidID
        OPT.usage '(opt) [id]'
      end
    end
  end
end
