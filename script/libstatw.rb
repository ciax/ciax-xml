#!/usr/bin/ruby
require "libmsg"
require "libstat"
require "libappstat"
require "libsymstat"
require "libsql"
require "libwatch"

# Status to StatW (String with attributes)
module StatW
  include Writable
  def init(adb,val)
    Msg.type?(adb,AppDb)
    self['val']=Msg.type?(val,AppStat)
    self['ver']=adb['app_ver'].to_i
    @sym=SymStat.new(adb,val).upd
    ['msg','class'].each{|k| self[k]=@sym[k] }
    @lastsave=0
    self['watch']=Watch.new(adb,self)
    self
  end

  def upd
    self['val'].upd
    @sym.upd
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

module StatLog
  def init
    # Logging if version number exists
    @sql=SqLog.new('value',self['id'],self['ver'],self['val'])
  end

  def upd
    super
    @sql.upd
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
    stat=Stat.new(idb['id']).extend(StatW).init(idb,val)
    print stat.upd.to_j
  rescue UserError
    Msg.usage "[id] < field_file"
  end
end
