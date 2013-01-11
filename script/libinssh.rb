#!/usr/bin/ruby
require "libinsdb"
require "libwatch"

module Ins
  module Sh
    def self.extended(obj)
      Msg.type?(obj,App::Exe)
      Msg.type?(obj,Int::Shell)
    end

    def ext_ins(id)
      @adb.ext_ins(id)
      cdb=@adb[:command]
      @extdom.add_db(cdb)
      (cdb[:alias]||{}).each{|k,v| @cobj[k]=@cobj[v]}
      @output=@print=Status::View.new(@adb,@stat).extend(Status::Print)
      @wview=Watch::View.new(@adb,@watch).ext_prt
      grp=@shdom.add_group('view',"Change View Mode")
      grp.add_item('pri',"Print mode").init_proc{@output=@print}
      grp.add_item('val',"Value mode").init_proc{@output=@stat['val']}
      grp.add_item('wat',"Watch mode").init_proc{@output=@wview} if @wview
      grp.add_item('raw',"Raw mode").init_proc{@output=@stat}
      self
    end
  end
end

module App::Exe
  def ext_ins(id)
    extend(Ins::Sh).ext_ins(id)
  end
end
