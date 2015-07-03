#!/usr/bin/ruby
require "libdatax"

module CIAX
  module App
    class Status < DataH
      # @ last*
      attr_reader :last
      def initialize(init_struct={})
        super('status',init_struct)
        @cls_color=13
        @last={}
        @updated=now_msec
        @lastsave=now_msec
      end

      def set_db(db)
        super
        if @data.empty?
          @adbs=@db[:status][:index]
          @data.update(@adbs.skeleton)
        end
        self
      end

      def change?(id)
        verbose("Compare(#{id}) current=[#{@data[id]}] vs last=[#{@last[id]}]")
        @data[id] != @last[id]
      end

      def update?
        self['time'] > @updated
      end

      def refresh
        verbose("Status Updated")
        @last.update(@data)
        @updated=self['time']
        self
      end
    end

    module File
      # @< (db),(base),(prefix)
      # @< (last)
      # @ lastsave
      include CIAX::File
      def self.extended(obj)
        Msg.type?(obj,Status)
      end

      def save(tag=nil)
        time=self['time']
        if time > @lastsave
          super
          @lastsave=time
        else
          verbose("Skip Save for #{time}")
        end
        self
      end
    end

    if __FILE__ == $0
      require "libinsdb"
      GetOpts.new('h:')
      stat=Status.new
      begin
        adb=Ins::Db.new.get(ARGV.shift)
        stat.set_db(adb)
        if host=$opt['h']
          stat.ext_http(host)
        else
          stat.ext_file
        end
        puts STDOUT.tty? ? stat : stat.to_j
      rescue InvalidID
        $opt.usage "(opt) [id]"
      end
      exit
    end
  end
end
