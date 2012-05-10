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
  extend Msg::Ver
  def initialize(val)
    Elapse.init_ver(self,5)
    @val=val
  end

  def to_f
    diff=(Time.now-Time.at(@val['time'].to_f)).to_f
    Elapse.msg{"Elapse update diff #{'%.3f' % diff} from #{@val['time']}"}
    diff
  end
end
