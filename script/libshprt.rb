#!/usr/bin/ruby
require "libappprt"
require "libwatchprt"

module ShPrt
  def init(adb)
    @output=@print=AppPrt.new(adb,@stat)
    @watch=WatchPrt.new(adb,@stat)
    cl=Msg::List.new("Change Mode",2)
    @cobj.list.push(cl)
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
