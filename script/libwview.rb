#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libappstat"
require "libsymstat"
require "libsql"
# Status to Wview (String with attributes)
class Wview < Rview
  def initialize(adb,field)
    Msg.type?(adb,AppDb)
    Msg.error("No ID in ADB") unless adb.key?('id')
    self['ver']=adb['version'].to_i if field.key?('ver')
    @stat=AppStat.new(adb,field).upd
    super(id=adb['id'])
    @sym=SymStat.new(adb,@stat).upd
    @sql=SqLog.new(id,self['ver'],@stat) if key?('ver')
    ['msg','class'].each{|k|
      self[k]=@sym[k]
    }
    @lastsave=0
  end

  def upd
    @v.msg{"Status update"}
    @stat.upd
    @sym.upd
    self
  end

  def set(hash)
    super
    @sym.upd
    self
  end

  def save
    time=@stat['time'].to_f
    if time > @lastsave
      super
      @sql.upd.flush if @sql
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
    idb=InsDb.new(id,true).cover_app
    field=Field.new(id).load
    view=Wview.new(idb,field)
    print view.upd.to_j
  rescue UserError
    Msg.usage "[id]"
  end
end
