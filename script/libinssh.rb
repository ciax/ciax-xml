#!/usr/bin/ruby
require "libinsdb"
require "libwatch"

# Should be included in App::Sh
module Ins
  module Sh
    def self.extended(obj)
      Msg.type?(obj,App::Main)
    end

    def init(id)
      idb=Ins::Db.new(id)
      @cobj.extcmd.add_db(idb[:command])
      @adb=idb.cover_app
      @output=@print=Status::View.new(@adb,@stat).extend(Status::Print)
      @wview=Watch::View.new(@adb,@stat).ext_prt
      grp=@shcmd.add_group('view',"Change View Mode")
      grp.add_item('pri',"Print mode").set_proc{@output=@print}
      grp.add_item('val',"Value mode").set_proc{@output=@stat.val}
      grp.add_item('wat',"Watch mode").set_proc{@output=@wview} if @wview
      grp.add_item('raw',"Raw mode").set_proc{@output=@stat}
      self
    end

    def exe(cmd)
      cmd[0]=(@adb[:command][:alias]||={})[cmd[0]]||cmd[0]
      super(cmd)
    end

    def to_s
      super
      @output.to_s
    end
  end
end

class App::Main
  def ext_ins(id)
    extend(Ins::Sh).init(id)
  end
end
