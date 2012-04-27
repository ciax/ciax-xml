#!/usr/bin/ruby
require "libview"
require "libwatch"

# Should be included in AppObj
module ShPrt
  def self.extended(obj)
    Msg.type?(obj,AppObj).init
  end

  def init
    @output=@print=View.new(@adb,@stat).extend(View::Print)
    @wview=Watch::View.new(@adb,@watch).extend(Watch::Print)
    cm=@cobj.list['mode']
    cm['pri']="Print mode"
    cm['val']="Value mode"
    cm['wat']="Watch mode" if @wview
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
    ''
  end

  def to_s
    @output.to_s
  end
end
