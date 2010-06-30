#!/usr/bin/ruby
class Verbose
  Start_time=Time.now
  def initialize(title)
    @title=title
  end

  # Public Method
  def msg
    return unless ENV['VER']
    msg=mkmsg(yield)
    if ENV['VER'].split(':').any? {|s|
        (msg+'all').upcase.include?(s.upcase) }
      warn msg
    end
  end

  def wrn
    warn mkmsg(yield)
  end

  def err(cond=nil)
    raise mkmsg(yield) unless cond
  end

  # Private Method
  private
  def mkmsg(text)
    pass=sprintf("%5.4f",Time.now-Start_time)
    "[#{pass}] #{@title}:#{text}".dump
  end
end
