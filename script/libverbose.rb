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
    raise color(msg,1)
  end

  def warn(msg='error')
    raise UserError,color(msg,3)
  end

  def list(list,title)
    err=color(title,2)+"\n"
    list.each{|key,val|
      if label=val['label']
        err << color(" %-10s" % key,3)+": #{label}\n"
      end
    }
    err
  end

  # Private Method
  private
  # 1=red,2=green,4=blue
  def color(text,color)
    return text unless STDERR.tty?
    "\033[3#{color}m#{text}\33[0m"
  end

  def mkmsg(text)
    return unless text
    pass=sprintf("%5.4f",Time.now-Start_time)
    ts= STDERR.tty? ? '' : "[#{pass}]"
    ts+'  '*@ind+color("#{@title}:",@color)+text.inspect
  end
end
