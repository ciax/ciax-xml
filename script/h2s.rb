#!/usr/bin/ruby
require "json"

usage="Usage: h2s < json_file\n"

field=JSON.load(gets(nil))
field.each{|k,v|
  printf(" %-6s : %s\n",k,v)
}
