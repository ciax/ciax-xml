#!/usr/bin/ruby
class Verbose

  def initialize(title=nil)
    @title=title.upcase
  end

  # Public Method
  public
  def msg(text='')
    warn mkmsg(text) if ENV['VER']
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
