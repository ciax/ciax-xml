#!/usr/bin/ruby
require "libview"
require "libwatch"

# Should be included in AppObj
module ShPrt
  def init
    @output=@print=View.new(@adb,@stat).extend(View::Print)
    @watch.extend(Watch::View).init(@adb).extend(Watch::Print)
    cm=@cobj.list['mode']
    cm.add('print'=>"Print mode")
    cm.add('value'=>"Value mode")
    cm.add('field'=>"Field mode") if @fint
    cm.add('watch'=>"Watch mode") if @watch
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
    when 'field'
      @output=@fint if @fint
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
