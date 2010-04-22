#!/usr/bin/ruby
require "libdev"
require "libstatio"
include StatIo
IoCmd="exio"

warn "Usage: devsrv [dev]" if ARGV.size < 1

dev=ARGV.shift
ddb=Dev.new(dev)

loop do 
  line=gets.chomp
  case line
  when /^q/
    break
  when /[\w]+/
    cmd,par=line.split(' ')
    ddb.devcom(cmd,par) do |ecmd|
      begin
        open("|#{IoCmd} #{dev} #{cmd}",'r+') do |f|
          f.puts ecmd
          f.gets(nil)
        end
      rescue
        puts $!
      end
    end
  else
    p ddb.stat
  end
end
