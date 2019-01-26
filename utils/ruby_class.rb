#!/usr/bin/ruby
# Class Tree
abort 'Usage: class_tree [files]' if STDIN.tty? && ARGV.empty?
all = []
mods = []
readlines.each do |line|
  next if /^( *)(class|module)/ !~ line

  rank = Regexp.last_match(1).length / 2
  mods[rank] = $'.strip
  all << mods[0, rank + 1].join('::') if /class/ =~ Regexp.last_match(2)
end
all.sort.uniq.each { |l| puts l }
