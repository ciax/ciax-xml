#!/usr/bin/ruby
abort "Usage: frmsim [id] (ver)" if ARGV.size < 1
id=ARGV.shift
ver=ARGV.shift
ARGV.clear
def pr(text)
  STDERR.print "\033[0;34m#{text}\33[0m"
end

def find_snd(fd,input,fname)
  while line=fd.gets
    snd=line.split("\t")
    rec=snd[2].chomp
    inp=[input.chomp].pack("m").split("\n").join('')
    if rec == inp
      pr "#{fname}:#{snd[1]}(#{fd.lineno})"
      rcv=fd.gets.split("\t")
      if /rcv/ === rcv[1]
        pr " -> rcv(#{fd.lineno})"
        sleep rcv[0].to_i-snd[0].to_i
        STDOUT.syswrite(rcv[2].unpack("m").first)
      end
      STDERR.puts
      break 1
    end
  end
end

begin
  10.times{
    Dir.glob(ENV['HOME']+"/.var/201?/frame_#{id}*.log").each{|fname|
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
