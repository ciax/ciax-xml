#!/usr/bin/ruby
module ModVer
  @@stime=Time.now

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
    caller=caller(2).first[/([\w]+?)'/,1]
    pass=sprintf("%5.4f",Time.now-@@stime)
    @title||='FILE'
    "[#{pass}] #{@title}:#{caller}:#{text}".dump
  end
end

