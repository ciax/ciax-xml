#!/usr/bin/ruby
require "lib0bjsrv"
require "libmodview"
require "readline"
include ModView

warn "Usage: objshell [obj]" if ARGV.size < 1

obj=ARGV.shift
odb=ObjSrv.new(obj)

loop {
  line=Readline.readline(odb.prompt,true)
  case line
  when /^q/
    break
  when ''
    line='stat'
  end
  puts odb.dispatch(line) { |s| view(s) }
}

