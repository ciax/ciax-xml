#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libwatch"
abort "Usage: watches [file]" if STDIN.tty? && ARGV.size < 1
begin
  stat=JSON.load(gets(nil))
  cdb=ClsDb.new(stat['class'])
  watch=Watch.new(cdb.watch)
  watch.update{|k| stat[k] }
  puts watch
rescue RuntimeError
  abort $!.to_s
end
