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
      @wview=Watch::View.new(@adb,@stat).extend(Watch::Print)
      @cobj.add_group('view',"Change View Mode")
      @cobj.add_case('view','pri',"Print mode"){@output=@print}
      @cobj.add_case('view','val',"Value mode"){@output=@stat.val}
      @cobj.add_case('view','wat',"Watch mode"){@output=@wview} if @wview
      @cobj.add_case('view','raw',"Raw mode"){@output=@stat}
      self
    end

    def to_s
      @output.to_s
    end
  end
end
