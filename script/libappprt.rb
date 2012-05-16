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
      vl={'pri'=>"Print mode",'val'=>"Value mode"}
      vl['wat']="Watch mode" if @wview
      @cmdlist.add_group('view',"Change View Mode",vl,2)
      self
    end

    def exe(cmd)
      case cmd.first
      when /^pri/
        @output=@print
      when /^val/
        @output=@stat.val
      when /^wat/
        @output=@wview
      when /^all/
        @output=@stat
      else
        return super
      end
      to_s
    end

    def to_s
      @output.to_s
    end
  end
end
