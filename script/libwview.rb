#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libappstat"
require "libsymstat"
require "libsql"
# Status to Wview (String with attributes)
class Wview < Rview
  def initialize(id,adb,field)
    super(id)
    @as=AppStat.new(adb,field)
    @stat.update(@as.upd)
    @sym=SymStat.new(adb,@as).upd
    @sql=Sql.new(id,@as)
    ['msg','class'].each{|k|
      self[k]=@sym[k]
    }
  end

  def upd
    @v.msg{"Status update"}
    @stat.update(@as.upd)
    self
  end

  def save
    if update?
      @sym.upd
      open(@uri,'w'){|f| f << to_j }
      @sql.upd.flush
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
    view=Wview.new(id,idb,field)
    print view.upd.to_j
  rescue UserError
    abort "Usage: #{$0} [id]\n#{$!}"
  end
end
