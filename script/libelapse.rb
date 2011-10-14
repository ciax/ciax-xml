#!/usr/bin/ruby
require "libmsg"
class Interval < Time
  def inspect
    '"'+to_s+'"'
  end

  def to_s
    sec=to_i
    if sec > 86400
      "%.1f days" % (sec/86400)
    elsif sec > 3600
      Time.at(sec).utc.strftime("%H:%M")
    else
      Time.at(sec).utc.strftime("%M'%S\"")
    end
  end
end

class Elapse < Interval
  def initialize(stat)
    @v=Msg::Ver.new('elapse',5)
    @stat=stat
  end

  def to_i
    @v.msg{"Elapse update"}
    (Time.now-Time.at(@stat['time'].to_f)).to_i
  end
end
