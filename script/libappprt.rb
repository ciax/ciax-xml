#!/usr/bin/ruby
require "libwatch"

# Should be included in App::Sh
module App
  module Prt
    def self.extended(obj)
      Msg.type?(obj,App::Sh).init
    end

    def init
      @output=@print=Status::View.new(@adb,@stat).extend(Status::Print)
      @wview=Watch::View.new(@adb,@stat).ext_prt
      grp=@shcmd.add_group('view',"Change View Mode")
      grp.add_item('pri',"Print mode").set_proc{@output=@print}
      grp.add_item('val',"Value mode").set_proc{@output=@stat.val}
      grp.add_item('wat',"Watch mode").set_proc{@output=@wview} if @wview
      grp.add_item('raw',"Raw mode").set_proc{@output=@stat}
      self
    end

    def to_s
      super
      @output.to_s
    end
  end
end
