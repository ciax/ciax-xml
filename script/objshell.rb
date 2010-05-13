#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libmodview"
include ModView

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
    begin
      odb.objcom(line) do |l|
        ddb.devcom(l)
      end
    rescue
      warn $!
    end
  else
    view(odb.stat)
  end
end
