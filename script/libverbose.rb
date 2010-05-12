#!/usr/bin/ruby
class Verbose
  Start_time=Time.now
  def initialize(title)
    @title=title
  end

  # Public Method
  def msg(text='',level=0)
    return unless ENV['VER']
    warn mkmsg(text) if ENV['VER'].to_i >= level
  end

  def err(text='')
    raise mkmsg(text)
  end

  # Private Method
  private
  def mkmsg(text)
    begin
      raise
    rescue
      stack=$@.length
    end
    caller=caller(2).first
    method=caller[/([\w]+?)'/,1]
    file=caller[/\/([\w]+?)\.rb/,1]
    pass=sprintf("%5.4f",Time.now-Start_time)
    "[#{pass}] #{@title}:#{stack}:#{file}:#{method}:#{text}".dump
  end
end
