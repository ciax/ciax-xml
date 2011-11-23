#!/usr/bin/ruby
require "libappprt"

module ModApp
  def init(adb)
    @output=@print=AppPrt.new(adb,@view)
    cl=Msg::List.new("Change Mode",2)
    @par.list.push(cl)
    cl.add('print'=>"Print mode")
    cl.add('stat'=>"Stat mode")
    cl.add('field'=>"Field mode") if @fint
    cl.add('watch'=>"Watch mode") if @watch
  end

  def exe(cmd)
    case cmd.first
    when 'print'
      @output=@print
    when 'stat'
      @output=@view['stat']
    when 'watch'
      @output=@watch if @watch
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
