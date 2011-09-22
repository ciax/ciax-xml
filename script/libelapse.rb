#!/usr/bin/ruby
require 'time'
class Elapse
  def initialize(stat)
    @stat=stat
  end

  def to_i
    Time.now-Time.parse(@stat['time']) rescue 0
  end

  def to_s
    sec=to_i
    if sec > 86400
      "%.1f days" % (sec/86400)
    elsif sec > 3600
      Time.at(sec).utc.strftime("%H:%M")
    elsif sec > 0
      Time.at(sec).utc.strftime("%M'%S\"")
    else
      '0'
    end
  end
end
