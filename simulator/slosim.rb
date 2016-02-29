#!/usr/bin/ruby
require 'gserver'

# Slosyn Driver Simulator
class Slosyn < GServer
  attr_accessor :spd, :e1, :e2
  attr_reader :err, :bs, :hl1, :hl0, :help
  RS = "\r\n"
  P_MAX = 9999
  P_MIN = 0
  POS = [1230, 128, 2005, 0, 1850]
  def initialize(port = 10_001, *args)
    super(port, *args)
    Thread.abort_on_exception = true
    @pulse = 0 # Integer
    @bs = 0
    @err = 0
    @spd = 0.1
    @hl1 = @hl0 = '>'
    @help = self.class.methods.inspect
  end

  def serve(io)
    @io = io
    while (cmd = io.gets(RS).chomp)
      sleep 0.1
      begin
        if /=/ =~ cmd
          method($` + $&).call($')
          res '>'
        elsif /\((.*)\)/ =~ cmd
          res method($`).call(Regexp.last_match(1))
        else
          res method(cmd).call
        end
      rescue NameError
        res '?'
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

  def res(str)
    @io.print str.to_s + RS
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
  end

  def p=(num)
    setpulse(setdec(num))
  end

  def p
    format('%.1f', @pulse.to_f / 10)
  end

  def ma=(num)
    servo(setdec(num))
  end

  def mi=(num)
    servo(@pulse + setdec(num))
  end

  def j=(num)
    case num.to_i
    when 1
      servo(2005)
    when -1
      servo(0)
    end
  end

  def stop
    @bs = 0
    '>'
  end

  def in(num)
    about(POS[num.to_i - 1])
  end
end

sv = Slosyn.new(*ARGV)
sv.start
sleep
