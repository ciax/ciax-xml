#!/usr/bin/ruby
require "json"
abort "Usage: labeling [file]" if STDIN.tty? && ARGV.size < 1

begin
  stat=JSON.load(gets(nil))
  if type=stat['frame']
    require "libfrmlabel"
    dv=FrmLabel.new(type)
  elsif type=stat['class']
    require "libclslabel"
    id=stat['id']
    dv=ClsLabel.new(type,id)
  else
    raise "NO ID in Stat"
  end
  puts JSON.dump(dv.merge(stat))
rescue
  abort $!.to_s
end
