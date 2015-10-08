#!/usr/bin/ruby
require 'gserver'

class Slosyn < GServer
  P_MAX = 9999
  P_MIN = 0
  POS = [1230, 128, 2005, 0, 1850]
  def initialize(port = 10_001, *args)
    super(port, *args)
    Thread.abort_on_exception = true
    @target = 0
    @pulse = 0
    @bs = 0
    Thread.new do
      loop do
        sleep 0.1
        diff = @target - @pulse
        if diff != 0
          @bs = 1
          @pulse += diff / diff.abs
          if @pulse > P_MAX
            @pulse = P_MIN
          elsif @pulse < P_MIN
            @pulse = P_MAX
          end
        else
          @bs = 0
        end
      end
    end
  end

  def serve(io)
    while (str = io.gets("\r").chomp)
      sleep 0.1
      case str
      when /^abspos=/
        @target = @pulse = set(str)
      when /^p=/
        @target = @pulse = set(str)
      when /^ma=/
        @target = set(str)
        @bs = 1
      when /^mi=/
        @target += set(str)
        @bs = 1
      when 'j=1'
        @target = 2005
        @bs = 1
      when 'j=-1'
        @target = 0
        @bs = 1
      when 'stop'
        @target = @pulse
      when /in\(([1-5])\)/
        io.print about(POS[Regexp.last_match(1).to_i - 1])
        next
      when 'spd'
        io.print '0.1'
        next
      when 'err'
        io.print '0'
        next
      when 'bs'
        io.print @bs
        next
      when 'p'
        io.print format('%.1f', @pulse.to_f / 10)
        next
      end
      io.print '>'
    end
  end

  def set(str)
    a = str.split('=')
    num = (a[1].to_f * 10).to_i
    if num > P_MAX
      num = P_MAX
    elsif num < P_MIN
      num = P_MIN
    end
    num
  end

  def about(x)
    (@pulse <= x + 5 && @pulse >= x - 5) ? '1' : '0'
  end

  # Commands
  def abspos=(num)
    @target = @pulse = set(num)
  end

  def p=(str)
    @target = @pulse = set(str)
  end
end

sv = Slosyn.new(*ARGV)
sv.start
sleep
