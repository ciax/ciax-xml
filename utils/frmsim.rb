#!/usr/bin/ruby
abort "Usage: frmsim [id]" if ARGV.size < 1
id=ARGV.shift
ARGV.clear

def find_snd(fd,input,fname)
  while line=fd.gets
    snd=line.split("\t")
    begin
      str=eval(snd[2])
    rescue Exception
      next
    end
    if str == input
      STDERR.print "#{fname}:snd(#{fd.lineno})"
      rcv=fd.gets.split("\t")
      if /rcv/ === rcv[1]
        STDERR.print ":rcv(#{fd.lineno})"
        sleep rcv[0].to_i-snd[0].to_i
        STDOUT.syswrite(eval(rcv[2]))
      end
      STDERR.puts
      break 1
    end
  end
end

begin
  10.times{
    Dir.glob(ENV['HOME']+"/.var/device_#{id}*.log").each{|fname|
      /#{id}[^\.]*/ =~ fname
      base=$&
      open(fname){|fd|
        select([STDIN]) while find_snd(fd,STDIN.sysread(1024),base)
        warn "no more line"
      }
    }
  }
rescue EOFError
end
