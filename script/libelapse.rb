#!/usr/bin/ruby
require 'time'
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
    @stat=Msg.type?(stat,Hash)
  end

  def update?
    return if @last == @stat['time']
    @last=@stat['time']
    self
  end

  def to_i
    return 0 if @stat['time'].to_s.empty?
    (Time.now-Time.parse(@stat['time'])).to_i
  end
end
