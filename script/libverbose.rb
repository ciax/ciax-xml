#!/usr/bin/ruby
class Verbose
  Start_time=Time.now
  def initialize(title)
    @title=title
  end

  # Public Method
  def msg(text='')
    return unless ENV['VER']
    m=mkmsg(text)
    if ENV['VER'].split(':').any? {|s|
        (m+'all').upcase.include?(s.upcase) }
      warn m
    end
  end

  def wrn(text='')
    warn mkmsg(text)
  end

  def err(text='')
    raise mkmsg(text)
  end

  # Private Method
  private
  def mkmsg(text)
    pass=sprintf("%5.4f",Time.now-Start_time)
    "[#{pass}] #{@title}:#{text}".dump
  end
end
