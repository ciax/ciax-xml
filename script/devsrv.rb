#!/usr/bin/ruby
require "libdev"
require "libstatio"
include StatIo
IoCmd="exio"

def execute(mode,dev,cmd)
end

warn "Usage: devsrv [dev]" if ARGV.size < 1

dev=ARGV.shift
ddb=Dev.new(dev)

while(line=gets.chomp)
  cmd,par=line.split(' ')
  ddb.devcom(cmd,par) do |ecmd|
    begin
      open("|#{IoCmd} #{dev} #{cmd}",'r+') do |f|
        f.puts ecmd
        p f.gets(nil)
      end
    rescue
      puts $!
    end
  end
end



