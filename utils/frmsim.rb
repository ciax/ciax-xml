#!/usr/bin/ruby
abort "Usage: frmsim [id]" if ARGV.size < 1
id=ARGV.shift
ARGV.clear
begin
  open(ENV['HOME']+"/.var/device_#{id}_2011.log"){|fd|
    loop{
      select([STDIN])
      input=STDIN.sysread(1024)
      while line=fd.gets
        cl=line.split("\t")
        if eval(cl[2]) == input
          nl=fd.gets.split("\t")
          if /rcv/ === nl[1]
            sleep nl[0].to_i-cl[0].to_i
            STDOUT.syswrite(eval(nl[2]))
          end
          break 1
        end
      end || fd.rewind
    }
  }
rescue Exception
  exit
end
