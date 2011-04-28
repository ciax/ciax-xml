#!/usr/bin/ruby
class Verbose
  Start_time=Time.now
  $DEBUG=true if ENV['VER']
  def initialize(title='',color=7)
    @title=title
    @color=color
    @@base=1
  end

  # Public Method
  def msg(ind=0)
    @@base+=ind
    return unless ENV['VER']
    ind=(ind > 0) ? -ind : 0
    msg=mkmsg(yield,ind) || return
    if ENV['VER'].split(':').any? {|s|
        (msg+'all').upcase.include?(s.upcase) }
      warn msg
    end
    return
  end

  def err(msg='error')
    raise mkmsg(msg)
  end

  # Private Method
  private
  def mkmsg(text,ind=0)
    return unless text
    ind+=@@base
    pass=sprintf("%5.4f",Time.now-Start_time)
    "[#{pass}]"+'  '*ind+color("#{@title}:#{text.inspect}",ind)
  end

  # 1=red,2=green,4=blue
  def color(text,ind)
    return text if ind > 1 || ! STDERR.tty?
    "\033[3#{@color}m#{text}\33[0m"
  end
end
