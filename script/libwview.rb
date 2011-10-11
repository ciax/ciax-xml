#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libappstat"
require "libsymstat"
require "libsql"
# Status to Wview (String with attributes)
class Wview < Rview
  attr_reader :sql
  def initialize(id,adb,field)
    super(id)
    @as=AppStat.new(adb,field)
    @sym=SymStat.new(adb,self)
    @sql=Sql.new(id,@as)
  end

  def upd
    super(@as.upd)
    @sym.upd
    @sql.upd
    self
  end

  def save
    open(@uri,'w'){|f| f << to_j }
    @sql.flush
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
    view=Wview.new(id,idb,field)
    print view.upd.to_j
  rescue UserError
    abort "Usage: #{$0} [id]\n#{$!}"
  end
end
