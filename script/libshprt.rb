#!/usr/bin/ruby
require "libview"
require "libwatch"

# Should be Included AppObj
module ShPrt
  def init
    @output=@print=View.new(@adb,@stat).extend(View::Print)
    @watch.extend(Watch::View).init(@adb).extend(Watch::Print)
    cl=Msg::CmdList.new("Change Mode",2)
    @cobj.list['mode']=cl
    cl.add('print'=>"Print mode")
    cl.add('value'=>"Value mode")
    cl.add('field'=>"Field mode") if @fint
    cl.add('watch'=>"Watch mode") if @watch
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
