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
        @updated=nowsec
        @lastsave=nowsec
      end

      def set(hash) #For Watch test
        @data.update(hash)
        upd
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
      require 'liblocdb'
      GetOpts.new('vh:')
      id=ARGV.shift
      host=ARGV.shift
      stat=Status.new
      begin
        if ! STDIN.tty?
          stat.read
          id=stat['id']
        else
          adb=Loc::Db.new.set(id)[:app]
          if host=$opt['h']
            stat.ext_http(id,host).load
          else
            stat.ext_file(id).load
          end
        end
        puts stat
      rescue InvalidID
        $opt.usage "(opt) [id] <(stat_file)"
      end
      exit
    end
  end
end
