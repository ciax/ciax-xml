#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libwatch"
abort "Usage: watches [file]" if STDIN.tty? && ARGV.size < 1
begin
  str=gets(nil) || exit
  stat=JSON.load(str)
  cdb=ClsDb.new(stat['class'])
  watch=Watch.new(cdb,stat)
  watch.update
  puts watch
rescue RuntimeError
  abort $!.to_s
end
