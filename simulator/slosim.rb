#!/usr/bin/ruby
require 'gserver'

# Slosyn Driver Simulator
class Slosyn < GServer
  P_MAX = 9999
  P_MIN = 0
  POS = [1230, 128, 2005, 0, 1850]
  def initialize(port = 10_001, *args)
    super(port, *args)
    Thread.abort_on_exception = true
    @pulse = 0 # Integer
    @bs = 0
    @q = Queue.new
  end

  def serve(io)
    while (str = io.gets("\r").chomp)
      sleep 0.1
      begin
        method(str).call
      rescue NameError
        io.print '>'
      end
    end
  end

  def servo(target)
    Thread.new(target.to_i) do |t|
      @bs = 1
      loop do
        diff = t - @pulse
        @bs = 0 if diff == 0
        break if @bs == 0
        setpulse(@pulse + (diff <=> 0))
        sleep 0.1
      end
    end
  end

  def setpulse(num)
    if num > P_MAX
      num = P_MIN
    elsif num < P_MIN
      num = P_MAX
    end
    @pulse = num
  end

  def setdec(n)
    (n.to_f * 10).to_i
  end

  def about(x)
    (@pulse <= x + 5 && @pulse >= x - 5) ? '1' : '0'
  end

  # Commands
  def abspos=(num)
    setpulse(setdec(num))
    io.print '>'
  end

  def p=(num)
    setpulse(setdec(num))
    io.print '>'
  end

  def ma=(num)
    servo(setdec(num))
    io.print '>'
  end

  def mi=(num)
    servo(@pulse + setdec(num))
    @q << @pulse
    @bs = 1
    io.print '>'
  end

  def j=(num)
    case num.to_i
    when 1
      servo(2005)
    when -1
      servo(0)
    end
    io.print '>'
  end

  def stop
    @bs = 0
    ''
  end

  def in(num)
    io.print about(POS[num.to_i - 1])
  end

  def spd
    io.print '0.1'
  end

  def err
    io.print '0'
  end

  def bs
    io.print @bs
  end

  def p
    io.print format('%.1f', @pulse.to_f / 10)
  end
end

sv = Slosyn.new(*ARGV)
sv.start
sleep
