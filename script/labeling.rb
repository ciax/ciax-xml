#!/usr/bin/ruby
require "json"
require "libmods2q"
include S2q
abort "Usage: labeling [file]" if STDIN.tty? && ARGV.size < 1

begin
  stat=s2q(JSON.load(gets(nil)))
  if type=stat['header']['frame']
    require "libfrmlabel"
    dv=FrmLabel.new(type)
  elsif type=stat['header']['class']
    require "libclslabel"
    id=stat['header']['id']
    dv=ClsLabel.new(type,id)
  else
    raise "NO ID in Stat"
  end
  puts JSON.dump(dv.convert(stat))
rescue
  abort $!.to_s
end
