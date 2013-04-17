#!/usr/bin/ruby
require "libmsg"
class Elapse < Time
  def initialize(base=Time.now)
    @base=Msg.type?(base,Time)
  end

  def inspect
    '"'+to_s+'"'
  end

  def to_f
    (Time.now-@base).to_f
  end

  def to_s
    sec=to_f
    if sec > 86400
      "%.1f days" % (sec/86400)
    elsif sec > 3600
      Time.at(sec).utc.strftime("%H:%M")
    elsif sec > 60
      Time.at(sec).utc.strftime("%M'%S\"")
    else
      Time.at(sec).utc.strftime("%S\"%L")
    end
  end
end
