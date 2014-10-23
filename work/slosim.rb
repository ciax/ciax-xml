#!/usr/bin/ruby
require 'gserver'

class Slosyn < GServer
  Pmax=9999
  Pmin=0
  Pos=[1230,128,2005,0,1850]
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
          if @pulse > Pmax
            @pulse=Pmin
          elsif @pulse < Pmin
            @pulse=Pmax
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
        @target=2005
        @bs=1
      when 'j=-1'
        @target=0
        @bs=1
      when 'stop'
        @target=@pulse
      when /in\(([1-5])\)/
        io.print about(Pos[$1.to_i-1])
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
    if num > Pmax
      num=Pmax
    elsif num < Pmin
      num=Pmin
    end
    num
  end

  def about(x)
    (@pulse <= x+5 && @pulse >= x-5) ? '1' : '0'
  end
end

sv=Slosyn.new(*ARGV)
sv.start
sleep
