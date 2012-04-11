#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libelapse"

class Stat < IoFile
  def initialize(id=nil,host=nil)
    super('stat',id,host)
    @last={}
  end

  def get(id)
    @v.msg{"getting status of #{id}"}
    case id
    when 'elapse'
      @elapse
    else
      self['val'][id]
    end
  end

  def set(hash) #For Watch test
    self['val'].update(hash)
    self['val']['time']=Msg.now
    self
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{self['val'][id]}] vs last=[#{@last[id]}]"}
    self['val'][id] != @last[id]
  end

  def update?
    change?('time')
  end

  def refresh
    @v.msg{"Status Updated"}
    @last.update(self['val'])
  end
end

# Status to Stat::Writable (String with attributes)
module Stat::Writable
  require "libappval"
  require "libsymstat"
  include IoFile::Writable
  def init(adb,val)
    Msg.type?(adb,AppDb)
    self['val']=Msg.type?(val,AppVal)
    self['ver']=adb['app_ver'].to_i
    @sym=SymStat.new(adb,val).upd
    ['msg','class'].each{|k| self[k]=@sym[k] }
    @lastsave=0
    self
  end

  def upd
    self['val'].upd
    @sym.upd
    self
  end

  def save
    time=self['val']['time'].to_f
    if time > @lastsave
      super
      @lastsave=time
      true
    end
  end
end

module Stat::Logging
  require "libsql"
  def init
    # Logging if version number exists
    @sql=Sql::Logging.new('value',self['id'],self['ver'],self['val'])
  end

  def upd
    super
    @sql.upd
    self
  end

  def save
    super && @sql.flush
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
      puts Stat.new(id,host).load
    else
      field=Field.new.load
      val=AppVal.new(idb,field)
      stat=Stat.new(idb['id']).extend(Stat::Writable).init(idb,val)
      print stat.upd.to_j
    end
  rescue UserError
    Msg.usage "[id] (host | < field_file)"
  end
end
