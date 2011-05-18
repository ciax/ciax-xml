#!/usr/bin/ruby
require "json"

abort "Usage: merging [orgfile] < input\n#{$!}" if ARGV.size < 1

file=ARGV.shift
h={}
open(file){|f|
  h=JSON.load(f.gets(nil))
}
input=JSON.load(STDIN.gets(nil))
h.update(input)
open(file,'w'){|f|
  f.puts(JSON.dump(h))
}
