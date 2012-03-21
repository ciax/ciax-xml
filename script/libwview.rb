#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libappstat"
require "libsymstat"
require "libsql"
require "libwatch"

# Status to Wview (String with attributes)
class Wview < Rview
  include Writable
  def initialize(adb,stat,logging=nil)
    id=Msg.type?(adb,AppDb)['id'] || Msg.error("No ID in ADB")
    self['stat']=Msg.type?(stat,AppStat)
    super(id)
    self['ver']=adb['app_ver'].to_i
    @sym=SymStat.new(adb,stat).upd
    # Logging if version number exists
    @sql=SqLog.new('stat',id,self['ver'],stat) if logging
    ['msg','class'].each{|k| self[k]=@sym[k] }
    @lastsave=0
    self['watch']=Watch.new(adb,self)
  end

  def upd
    @v.msg{"Update(#{self['stat']['time']})"}
    self['stat'].upd
    @sym.upd
    @sql.upd if @sql
    self['watch'].upd
    self
  end

  def save
    time=self['stat']['time'].to_f
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
    field=Field.new(id).load
    view=Wview.new(idb,field)
    print view.upd.to_j
  rescue UserError
    Msg.usage "[id]"
  end
end
