#!/usr/bin/ruby
require "libdev"
require "libcls"
require "readline"

warn "Usage: clsshell [class] [iocmd] (obj)" if ARGV.size < 2

cls=ARGV.shift
iocmd=ARGV.shift
obj=ARGV.shift || cls
cdb=Cls.new(cls,obj)
ddb=DevCom.new(cdb['device'],iocmd,obj)

loop{
  line=Readline.readline("#{cls}>",true).chomp
  case line
  when /^q/
    break
  when /[\w]+/
    begin
      cdb.setcmd(line)
      cdb.clscom{|cmd|
        ddb.setcmd(cmd)
        ddb.devcom
        cdb.get_stat(ddb.field)
      }
    rescue
      puts $!
    end
  else
    p cdb.stat
  end
}
