#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libvar"

class Stat < Var
  def initialize
    super('stat')
    @last={}
  end

  def get(id)
    @v.msg{"getting status of #{id}"}
    @val[id]
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

# Status to Stat::Convert (String with attributes)
module Stat::Convert
  require "libappval"
  require "libsymstat"
  include IoFile
  def init(adb,val)
    super(adb['id'])
    Msg.type?(adb,AppDb)
    self.val=Msg.type?(val,AppVal)
    self['ver']=adb['app_ver'].to_i
    @sym=SymStat.new(adb,val).upd
    ['msg','class'].each{|k| self[k]=@sym[k] }
    @lastsave=0
    self
  end

  def upd
    @val.upd
    @sym.upd
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

module Stat::Logging
  require "libsqlog"
  def self.extended(obj)
    Msg.type?(obj,Stat::Convert).init
  end

  def init
    # Logging if version number exists
    @sql=SqLog::Logging.new('value',self['id'],self['ver'],@val)
    self
  end

  def upd
    super
    @sql.upd
    self
  end

  def save
    super && @sql.save
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libfield"
  begin
    id=ARGV.shift
    host=ARGV.shift
    ARGV.clear
    idb=InsDb.new(id).cover_app
    if STDIN.tty?
      if host
        puts Stat.new.extend(InUrl).init(id,host).load
      else
        puts Stat.new.extend(InFile).init(id).load
      end
    else
      field=Field.new.load
      val=AppVal.new(idb,field)
      stat=Stat.new.extend(Stat::Convert).init(idb,val)
      print stat.upd.to_j
    end
  rescue UserError
    Msg.usage "[id] (host | < field_file)"
  end
end
