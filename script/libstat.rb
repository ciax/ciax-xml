#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libvar"

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
  include IoFile
  def self.extended(obj)
    Msg.type?(obj,SymConv).init
  end

  def init
    super(@id)
    @lastsave=0
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

module Stat::SqLog
  require "libsqlog"
  def self.extended(obj)
    Msg.type?(obj,Stat::IoFile).init
  end

  def init
    # Logging if version number exists
    @sql=SqLog.new('value',@id,@ver,@val).extend(SqLog::Exec)
    @post_upd << proc {@sql.upd}
  end

  def save
    super && @sql.save
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libfield"
  require "libapprsp"
  begin
    id=ARGV.shift
    host=ARGV.shift
    ARGV.clear
    idb=InsDb.new(id).cover_app
    stat=Stat.new
    if STDIN.tty?
      if host
        puts stat.extend(InUrl).init(id,host).load
      else
        puts stat.extend(InFile).init(id).load
      end
    else
      field=Field.new.load
      val=App::Rsp.new(idb,field).upd
      print stat.upd
    end
  rescue UserError
    Msg.usage "[id] (host | < field_file)"
  end
end
