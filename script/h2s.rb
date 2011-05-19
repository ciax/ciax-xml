#!/usr/bin/ruby
require "json"

abort "Usage: h2s < json_file" if STDIN.tty?
str=gets(nil) || exit
field=JSON.load(str)
field.each{|k,v|
  printf(" %-6s : %s\n",k,v)
}

