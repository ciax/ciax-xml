#!/usr/bin/ruby

class UserError < RuntimeError; end

class Verbose
  Start_time=Time.now
  $DEBUG=true if ENV['VER']
  @@base=1
  def initialize(title='',color=7)
    @title=title.upcase
    @color=color
    @ind=1
 end

  # Public Method
  def msg(add=0)
    return unless ENV['VER']
    @ind=@@base
    @@base+=add
    @ind=@@base if add < 0
    msg=mkmsg(yield) || return
    if ENV['VER'].split(':').any? {|s|
        (msg+'all').upcase.include?(s.upcase) }
      Kernel.warn msg
    end
    return
  end

  def err(msg='error')
    raise Verbose.color(msg,1)
  end

  def warn(msg='error')
    raise UserError,Verbose.color(msg,3)
  end

  # 1=red,2=green,4=blue
  def Verbose.color(text,color)
    return text unless STDERR.tty?
    "\033[3#{color}m#{text}\33[0m"
  end

  # Private Method
  private
  def mkmsg(text)
    return unless text
    pass=sprintf("%5.4f",Time.now-Start_time)
    ts= STDERR.tty? ? '' : "[#{pass}]"
    ts+'  '*@ind+Verbose.color("#{@title}:",@color)+text.inspect
  end
end
