#!/usr/bin/ruby
require "libappprt"

module ShPrt
  def init(adb)
    @output=@print=AppPrt.new(adb,@view)
    @watch=@view['watch'].extend(WatchPrt)
    cl=Msg::List.new("Change Mode",2)
    @cobj.list.push(cl)
    cl.add('print'=>"Print mode")
    cl.add('stat'=>"Stat mode")
    cl.add('field'=>"Field mode") if @fint
    cl.add('watch'=>"Watch mode") if @watch
    self
  end

  def exe(cmd)
    case cmd.first
    when 'print'
      @output=@print
    when 'stat'
      @output=@view['stat']
    when 'watch'
      @output=@watch
    when 'field'
      @output=@fint if @fint
    else
      return super
    end
    nil
  end

  def to_s
    @output.to_s
  end
end
