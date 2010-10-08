#!/usr/bin/ruby
class Verbose
  Start_time=Time.now
  def initialize(title)
    @title=title
    @base=1
  end

  # Public Method
  def msg(ind=0)
    @base+=ind
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
    ind+=@base
    pass=sprintf("%5.4f",Time.now-Start_time)
    "[#{pass}]"+'  '*ind+@title+":"+text.inspect
  end
end
