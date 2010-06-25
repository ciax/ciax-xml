#!/usr/bin/ruby
require "libobjsrv"
require "libmodview"
include ModView

warn "Usage: objshell [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=ObjSrv.new(obj)

loop {
  line=gets.chomp
  case line
  when /^q/
    break
  when ''
    line='stat'
  end
  print odb.dispatch(line) { |s| view(s) }
}

