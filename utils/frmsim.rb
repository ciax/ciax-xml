#!/usr/bin/ruby
require "json"

abort "Usage: frmsim [id] (ver)" if ARGV.size < 1
id=ARGV.shift
ver=ARGV.shift
ARGV.clear
def pr(text)
  STDERR.print "\033[1;34m#{text}\33[0m"
end

def find_snd(fd,input,fname)
  inp=[input.chomp].pack("m").split("\n").join('')
  while line=fd.gets
    next unless /#{inp}/ === line
    snd=JSON.load(line)
    sl=fd.lineno
    rcv=JSON.load(fd.gets)
    next unless /rcv/ === rcv['dir']
    pr "#{fname}:#{snd['cmd']}(#{sl}) -> rcv(#{fd.lineno})\n"
    sleep rcv['time'].to_i-snd['time'].to_i
    STDOUT.syswrite(rcv['base64'].unpack("m").first)
    break 1
  end
end

begin
  100.times begin
    Dir.glob(ENV['HOME']+"/.var/stream_#{id}*.log").each{|fname|
      /#{id}[^\.]*/ =~ fname
      base=$&
      open(fname){|fd|
        select([STDIN]) while find_snd(fd,STDIN.sysread(1024),base)
      }
    }
  end
rescue EOFError
end
