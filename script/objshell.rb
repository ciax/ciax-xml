#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libmodview"
include ModView

warn "Usage: objshell [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=Obj.new(obj)
dev=odb['device']
iocmd=odb['client']
ddb=DevCom.new(dev,iocmd,obj)

loop {
  print "#{obj}>"
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    begin
      odb.objcom(line) {|c,p|
        begin
          ddb.setpar(p)
          ddb.setcmd(c)
          ddb.devcom
        rescue
          warn $!
        end
      }
    rescue
      warn $!
    end
  else
    view(odb.stat)
  end
}

