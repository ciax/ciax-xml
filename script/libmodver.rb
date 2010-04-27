#!/usr/bin/ruby
module ModVer

  # Public Method
  public
  def set_title(title)
    @title=title.upcase
    @@stime=Time.now
  end

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
    pass=sprintf("%5.4f",Time.now-@@stime)
    "[#{pass}] #{@title}:#{caller}:#{text}".dump
  end
end

