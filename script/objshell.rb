#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libmodview"
require "libmodfile"
include ModView
include ModFile
warn "Usage: objshell [obj] (iocmd)" if ARGV.size < 2

obj=ARGV.shift
odb=Obj.new(obj)
dev=odb.property['device']
iocmd=ARGV.shift
ddb=Dev.new(dev,iocmd)

loop do 
  print "#{obj}>"
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    cmd,par=line.split(' ')
    begin
      odb.objcom(cmd,par) do |c,p|
        save_stat(dev,ddb.devcom(c,p))
        ddb.stat
      end
      save_stat(obj,odb.stat)
    rescue
      warn $!
    end
  else
    view(odb.stat)
  end
end



