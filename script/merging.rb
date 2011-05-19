#!/usr/bin/ruby
require "json"

abort "Usage: merging [orgfile] < input\n#{$!}" if STDIN.tty? && ARGV.size < 1

file=ARGV.shift
h={}
open(file){|f|
  h=JSON.load(f.gets(nil))
}
str=STDIN.gets(nil) || exit
input=JSON.load(str)
h.update(input)
open(file,'w'){|f|
  f.puts(JSON.dump(h))
}
