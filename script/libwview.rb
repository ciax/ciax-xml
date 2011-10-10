#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libsymstat"
# Status to Wview (String with attributes)
class Wview < Rview
  def initialize(id,adb,stat)
    super(id)
    @sym=SymStat.new(adb)
    self['stat']=Msg.type?(stat,AppStat)
  end

  def upd
    update(@sym.mksym(self['stat']))
  end

  def save
    open(@uri,'w'){|f| f << to_j }
    self
  end
end

if __FILE__ == $0
  require "libappdb"
  require "libfield"
  require "libappstat"
  app=ARGV.shift
  ARGV.clear
  begin
    adb=AppDb.new(app,true)
    str=gets(nil) || exit
    field=Field.new.update_j(str)
    as=AppStat.new(adb,field).upd
    view=Wview.new(field['id'],adb,as)
    print view.upd.to_j
  rescue UserError
    abort "Usage: #{$0} [app] < field_file\n#{$!}"
  end
end
