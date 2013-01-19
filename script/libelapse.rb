#!/usr/bin/ruby
require "libmsg"
class Interval < Time
  def inspect
    '"'+to_s+'"'
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

class Elapse < Interval
  def initialize(var)
    @var=var
  end

  def to_f
    (Time.now-Time.at(@var['time'].to_f)).to_f
  end
end
