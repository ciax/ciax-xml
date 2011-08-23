#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libwatch"
abort "Usage: watches (test conditions (key=val)..) < [file]" if STDIN.tty?
hash={}
conds,cmds=ARGV.partition{|i| i.include?("=")}
conds.each{|s|
  k,v=s.split("=")
  hash[k]=v
}
cmd=cmds.join(" ")
ARGV.clear
  str=gets(nil) || exit
  stat=JSON.load(str)
begin
warn stat
  cdb=ClsDb.new(stat['class'])
rescue SelectID
  abort $!.to_s
end
  watch=Watch.new(cdb,stat.update(hash))
  watch.update
  puts watch.to_s
  print "Active? : "
  p watch.active?
  print "Block Pattern : "
  p watch.block_pattern
  print "Blocking? (#{cmd}) : "
  p watch.blocking?(cmd)
  print "Issue Commands : "
  p watch.issue
  print "Interrupt : "
  p watch.interrupt

