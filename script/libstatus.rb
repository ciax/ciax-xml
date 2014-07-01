#!/usr/bin/ruby
require "libdatax"

module CIAX
  module App
    class Status < Datax
      # @ last*
      attr_reader :last
      def initialize(init_struct={})
        @ver_color=6
        super('status',init_struct)
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

      def set(hash) #For Watch test
        @data.update(hash)
        self
      ensure
        post_upd
      end

      def change?(id)
        verbose("Status","Compare(#{id}) current=[#{@data[id]}] vs last=[#{@last[id]}]")
        @data[id] != @last[id]
      end

      def update?
        self['time'] > @updated
      end

      def refresh
        verbose("Status","Status Updated")
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
          verbose("Status","Skip Save for #{time}")
        end
        self
      end
    end

    if __FILE__ == $0
      require 'libsitedb'
      GetOpts.new('h:')
      stat=Status.new
      begin
        adb=Site::Db.new.set(ARGV.shift)[:adb]
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
