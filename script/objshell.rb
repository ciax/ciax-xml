#!/usr/bin/ruby
require "libobjsrv"
require "libmodview"
include ModView

warn "Usage: objshell [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=ObjSrv.new(obj)

loop {
  print "#{obj}>"
  line=gets.chomp
  case line
  when /^q/
    break
  when '','stat'
    odb.dispatch('stat') { |s| view(s) }
  else
    puts odb.dispatch(line)
  end
}

