#!/usr/bin/ruby
require "libobj2"
require "libdev"
require "libmodview"
include ModView

warn "Usage: objshell [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=Obj.new(obj)
dev=odb.property['device']
iocmd=odb.property['client']
ddb=Dev.new(dev,iocmd,obj)

loop {
  print "#{obj}>"
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    begin
      odb.objcom(line) {|l|
        begin
          ddb.devcom(l)
        rescue
          warn $!
        end
      }
    rescue
      warn $!
      warn $@
    end
  else
    view(odb.stat)
  end
}
