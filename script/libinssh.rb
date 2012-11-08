#!/usr/bin/ruby
require "libinsdb"
require "libwatch"

# Should be included in App::Sh
module Ins
  module Sh
    def self.extended(obj)
      Msg.type?(obj,App::Exe)
      Msg.type?(obj,Int::Shell)
    end

    def init(id)
      @adb.ext_ins(id)
      cdb=@adb[:command]
      @extcmd.add_db(cdb)
      (cdb[:alias]||{}).each{|k,v| @cobj[k]=@cobj[v]}
      @output=@print=Status::View.new(@adb,@stat).extend(Status::Print)
      @wview=Watch::View.new(@adb,@stat).ext_prt
      grp=@shcmd.add_group('view',"Change View Mode")
      grp.add_item('pri',"Print mode").init_proc{@output=@print}
      grp.add_item('val',"Value mode").init_proc{@output=@stat.val}
      grp.add_item('wat',"Watch mode").init_proc{@output=@wview} if @wview
      grp.add_item('raw',"Raw mode").init_proc{@output=@stat}
      self
    end

    def to_s
      super
      @output.to_s
    end
  end
end

class App::Exe
  def ext_ins(id)
    extend(Ins::Sh).init(id)
  end
end
