#!/usr/bin/ruby

class UserError < RuntimeError; end

class Verbose
  Start_time=Time.now
  $DEBUG=true if ENV['VER']
  def initialize(title='',color=7)
    @title=title.upcase
    @color=color
    @@base=1
 end

  # Public Method
  def msg(ind=0)
    return unless ENV['VER']
    @ind=@@base
    @@base+=ind
    @ind=@@base if ind < 0
    msg=mkmsg(yield) || return
    if ENV['VER'].split(':').any? {|s|
        (msg+'all').upcase.include?(s.upcase) }
      Kernel.warn msg
    end
    return
  end

  def err(msg='error')
    raise color(msg,1)
  end

  def warn(msg='error')
    raise UserError,color(msg,3)
  end

  # 1=red,2=green,4=blue
  def color(text,color=@color)
    return text unless STDERR.tty?
    "\033[3#{color}m#{text}\33[0m"
  end

  # Private Method
  private
  def mkmsg(text)
    return unless text
    pass=sprintf("%5.4f",Time.now-Start_time)
    ts= STDERR.tty? ? '' : "[#{pass}]"
    ts+indent+color("#{@title}:")+text.inspect
  end

  def indent
    '  '*@ind
  end
end
