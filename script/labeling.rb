#!/usr/bin/ruby
require "json"
require "libmods2q"
require "liblabel"
include S2q
abort "Usage: labeling [file]" if STDIN.tty? && ARGV.size < 1

begin
  stat=s2q(JSON.load(gets(nil)))
  if type=stat['header']['frame']
    require "libfrmdb"
    fdb=FrmDb.new(type)
    dv=Label.new.update(fdb.label)
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
