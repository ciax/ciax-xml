#!/usr/bin/ruby
require "libmsg"
require "libvar"

module App
  class Stat < Var
    def initialize
      super('stat')
      @last={}
    end

    def set(hash) #For Watch test
      @val.update(hash)
      self
    end

    def change?(id)
      @v.msg{"Compare(#{id}) current=[#{@val[id]}] vs last=[#{@last[id]}]"}
      @val[id] != @last[id]
    end

    def update?
      change?('time')
    end

    def refresh
      @v.msg{"Status Updated"}
      @last.update(@val)
    end
  end

  module Stat::IoFile
    require "libiofile"
    include IoFile
    def self.extended(obj)
      Msg.type?(obj,SymConv).init
    end

    def init
      super(@id)
      @lastsave=0
      self
    end

    def upd
      super
      save
      self
    end

    def save
      time=@val['time'].to_f
      if time > @lastsave
        super
        @lastsave=time
        true
      end
    end
  end
end

if __FILE__ == $0
  require "libinsdb"
  begin
    id=ARGV.shift
    host=ARGV.shift
    ARGV.clear
    idb=InsDb.new(id).cover_app
    stat=App::Stat.new
    if STDIN.tty?
      if host
        puts stat.extend(InUrl).init(id,host).load
      else
        puts stat.extend(InFile).init(id).load
      end
    else
      require "libfield"
      require "libapprsp"
      field=Field.new.load
      stat.extend(App::Rsp).init(idb,field).upd
      print stat
    end
  rescue UserError
    Msg.usage "[id] (host | < field_file)"
  end
  exit
end
