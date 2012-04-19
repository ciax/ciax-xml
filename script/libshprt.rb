#!/usr/bin/ruby
require "libview"
require "libwatch"

# Should be included in AppObj
module ShPrt
  def init
    @output=@print=View.new(@adb,@stat).extend(View::Print)
    @watch.extend(Watch::View).init(@adb).extend(Watch::Print)
    cm=@cobj.list['mode']
    cm['print']="Print mode"
    cm['value']="Value mode"
    cm['watch']="Watch mode" if @watch
    self
  end

  def exe(cmd)
    case cmd.first
    when 'print'
      @output=@print
    when 'value'
      @output=@stat['val']
    when 'watch'
      @output=@watch
    when 'all'
      @output=@stat
    else
      return super
    end
    nil
  end

  def to_s
    @output.to_s
  end
end
