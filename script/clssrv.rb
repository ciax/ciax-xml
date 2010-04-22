#!/usr/bin/ruby
require "libcls"
require "libdev"
require "libstatio"
include StatIo

warn "Usage: clssrv [cls]" if ARGV.size < 1

cls=ARGV.shift
cdb=Cls.new(cls)
dev=cdb.property['device']
ddb=Dev.new(dev,"exio #{dev}")

loop do 
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    cmd,par=line.split(' ')
    begin
      cdb.clscom(cmd,par) do |c,p|
        ddb.devcom(c,p)
      end
    rescue
      warn $!
    end
  else
    p cdb.stat
  end
end
