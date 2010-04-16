#!/usr/bin/ruby
class Verbose

  def initialize(title=nil)
    @title=title.upcase
  end

  # Public Method
  public
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
    caller=caller(2).first[/([\w]+?)'/,1].upcase
    "#{@title}:#{caller}:#{text}".dump
  end
end
