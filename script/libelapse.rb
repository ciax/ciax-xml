#!/usr/bin/ruby
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
  def initialize(num)
    @at=Time.at(num.to_f)
  end

  def update?
    return if @last == @at
    @last=@at
    self
  end

  def to_i
    (Time.now-@at).to_i
  end
end
