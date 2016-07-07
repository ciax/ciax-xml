#!/usr/bin/ruby
# Class Tree
abort 'Usage: class_tree [files]' if STDIN.tty? && ARGV.size < 1
all = []
mods = []
readlines.each do|line|
  next if /^( *)(class|module)/ !~ line
  rank = $1.length/2
  mods[rank]=$'.strip
  all <<  mods[0,rank+1].join('::') if /class/ =~ $2
end
all.sort.uniq.each {|l| puts l }
