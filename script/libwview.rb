#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libappstat"
require "libsymstat"
require "libsql"
# Status to Wview (String with attributes)
class Wview < Rview
  def initialize(id,adb,field)
    @stat=AppStat.new(adb,field).upd
    super(id)
    @sym=SymStat.new(adb,@stat).upd
    @sql=Sql.new(id,@stat)
    ['msg','class'].each{|k|
      self[k]=@sym[k]
    }
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

  def flush
    if update?
      refresh
      save
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

