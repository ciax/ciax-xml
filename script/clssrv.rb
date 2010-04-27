#!/usr/bin/ruby
require "libcls"
require "libdev"
require "libmodio"
include ModIo

warn "Usage: clssrv [cls] (iocmd)" if ARGV.size < 1

cls=ARGV.shift
cdb=Cls.new(cls)
dev=cdb.property['device']
iocmd=ARGV.shift || "exio #{dev}"
ddb=Dev.new(dev,iocmd)

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

