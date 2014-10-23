#!/usr/bin/ruby
require 'gserver'

class Slosyn < GServer
  def initialize(port=10001,*args)
    super(port,*args)
    Thread.abort_on_exception=true
    @target=0
    @pulse=0
    @bs=0
    Thread.new{
      loop{
        sleep 0.1
        diff=@target-@pulse
        if diff!=0
          @bs=1
          @pulse+=diff/diff.abs
          if @pulse > 9999
            @pulse-=10000
          elsif @pulse < 0
            @pulse+=10000
          end
        else
          @bs=0
        end
      }
    }
  end

  def serve(io)
    while str=io.gets("\r").chomp
      case str
      when /^abspos=/
        @target=@pulse=set(str)
      when /^p=/
        @target=@pulse=set(str)
      when /^ma=/
        @target=set(str)
        @bs=1
      when /^mi=/
        @target+=set(str)
        @bs=1
      when 'j=1'
        @target=2008
        @bs=1
      when 'j=-1'
        @target=0
        @bs=1
      when 'stop'
        @target=@pulse
      when 'in(1)'
        io.print within(1225,1235)
        next
      when 'in(2)'
        io.print within(123,132)
        next
      when 'in(3)'
        io.print within(2000,2010)
        next
      when 'in(4)'
        io.print within(0,5)
        next
      when 'in(5)'
        io.print within(1845,1855)
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
        io.print "%.1f" % (@pulse.to_f/10)
        next
      end
      io.print ">"
    end
  end

  def set(str)
    a=str.split('=')
    num=(a[1].to_f*10).to_i
    if num > 9999
      num=9999
    elsif num < 0
      num=0
    end
    num
  end

  def within(a,b)
    (@pulse <= b && @pulse >= a) ? '1' : '0'
  end
end

sv=Slosyn.new(*ARGV)
sv.start
sleep
