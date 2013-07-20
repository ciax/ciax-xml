#!/usr/bin/ruby
require "json"

class LogRing
  attr_reader :index,:max
  def initialize(id)
    @logary=[{}]
    @index=0
    ary=[]
    Dir.glob(ENV['HOME']+"/.var/stream_#{id}*.log").each{|fname|
      open(fname){|fd|
        while line=fd.gets
          hash=JSON.load(line)||next
          ary << hash
        end
      }
    }
    dict={}
    ary.sort_by{|h| h['time'] }.uniq.select{|h| h['id'] == id}.each{|h|
      data=h.delete('base64')
      case h.delete('dir')
      when 'snd'
        h['snd']=data
        dict[data]=''
        if @logary.last.key?('rcv')
          @logary << h
        else
          @logary.last.update h
        end
      when 'rcv'
        if @logary.last.key('rcv')
          pr 'rcv duplicated'
        elsif @logary.last['cmd'] == h['cmd']
          h['rcv']=data
          dur=h.delete('time').to_f*1000 - @logary.last['time'].to_f*1000
          h['dur']=dur.round/1000.0
          @logary.last.update h
        else
          pr 'no match'
        end
      end
    }
    @max=@logary.size-1
    @sndary=dict.keys
  end

  def find_next(str)
    if @sndary.include?(str)
      begin
        @index+=1
        @index=0 if @index > @max
      end until @logary[@index]['snd'] == str
      crnt=@logary[@index]
      pr "#{crnt['cmd']}(#{@index}/#{@max})\n" if /sim/ === ENV['VER']
      crnt
    else
      pr "Can't find logline for input of [#{str}]\n"
      nil
    end
  end

  def include?(str)
    @sndary.include?(str)
  end

  def to_s
    @logary.map{|e|
      e.to_s
    }.join("\n")
  end

  private
  def pr(text)
    STDERR.print "\033[1;34m#{text}\33[0m"
  end
end


def input
  select([STDIN])
  [STDIN.sysread(1024).chomp].pack("m").split("\n").join('')
end

abort "Usage: frmsim [id] (ver)" if ARGV.size < 1
id=ARGV.shift
ver=ARGV.shift
ARGV.clear

logv=LogRing.new(id)
begin
  while inp=input
    if crnt=logv.find_next(inp)
      sleep crnt['dur'].to_i
      STDOUT.syswrite(crnt['rcv'].unpack("m").first)
    end
  end
rescue EOFError
end
