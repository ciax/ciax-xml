#!/usr/bin/ruby
require "libmsg"
require "libstat"
require "libappstat"
require "libsymstat"
require "libsql"
require "libwatch"

# Status to Wview (String with attributes)
class Wview < Stat
  include Writable
  def initialize(adb,val,logging=nil)
    id=Msg.type?(adb,AppDb)['id'] || Msg.error("No ID in ADB")
    self['val']=Msg.type?(val,AppStat)
    super(id)
    self['ver']=adb['app_ver'].to_i
    @sym=SymStat.new(adb,val).upd
    # Logging if version number exists
    @sql=SqLog.new('value',id,self['ver'],val) if logging
    ['msg','class'].each{|k| self[k]=@sym[k] }
    @lastsave=0
    self['watch']=Watch.new(adb,self)
  end

  def upd
    self['val'].upd
    @v.msg{"Update(#{self['val']['time']})"}
    @sym.upd
    @sql.upd if @sql
    self['watch'].upd
    self
  end

  def save
    time=self['val']['time'].to_f
    if time > @lastsave
      super
      @sql.flush if @sql
      @lastsave=time
    end
    self
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libfield"
  id=ARGV.shift
  ARGV.clear
  begin
    idb=InsDb.new(id).cover_app
    field=Field.new.load
    val=AppStat.new(idb,field)
    stat=Wview.new(idb,val)
    print stat.upd.to_j
  rescue UserError
    Msg.usage "[id] < field_file"
  end
end
