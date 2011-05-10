#!/usr/bin/ruby
require "json"
require "libmods2q"
require "liblabel"
require "libobjdb"

include S2q
abort "Usage: labeling [file]" if STDIN.tty? && ARGV.size < 1

stat=s2q(JSON.load(gets(nil)))
if type=stat['header']['frame']
  require "libfrmdb"
  fdb=FrmDb.new(type)
  dv=Label.new(fdb.label)
elsif type=stat['header']['class']
  require "libclsdb"
  id=stat['header']['id']
  cdb=ClsDb.new(type)
  dv=Label.new(cdb.label)
  begin
    ObjDb.new(id).override(dv)
  rescue SelectID
  end
else
  raise "NO ID in Stat"
end
puts JSON.dump(dv.convert(stat))
