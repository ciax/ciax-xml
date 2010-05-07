#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libmodview"
require "libmodfile"
include ModView
include ModFile
warn "Usage: clssrv [cls] (iocmd)" if ARGV.size < 2

cls=ARGV.shift
cdb=Cls.new(cls)
dev=cdb.property['device']
iocmd=ARGV.shift
ddb=Dev.new(dev,iocmd)

loop do 
  print "#{cls}>"
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    cmd,par=line.split(' ')
    begin
      cdb.clscom(cmd,par) do |c,p|
        save_stat(dev,ddb.devcom(c,p))
        ddb.stat
      end
      save_stat(cls,cdb.stat)
    rescue
      warn $!
    end
  else
    view(cdb.stat)
  end
end
