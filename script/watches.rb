#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libwatch"
abort "Usage: watches [file]" if STDIN.tty? && ARGV.size < 1
begin
  stat=JSON.load(gets(nil))
  doc=XmlDoc.new('cdb',stat['class'])
  watch=Watch.new(doc['watch'])
  watch.update{|k| stat[k] }
  puts JSON.dump(watch)
rescue RuntimeError
  abort $!.to_s
end
