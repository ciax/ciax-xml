#!/usr/bin/ruby
require "json"
require "libmods2q"
require "libgroup"
require "libobjdb"

include S2q
abort "Usage: grouping [file]" if STDIN.tty? && ARGV.size < 1

stat=s2q(JSON.load(gets(nil)))
if type=stat['header']['frame']
  require "libfrmdb"
  fdb=FrmDb.new(type)
  dv=Group.new(fdb.group)
elsif type=stat['header']['class']
  require "libclsdb"
  id=stat['header']['id']
  cdb=ClsDb.new(type)
  dv=Group.new(cdb.group)
  begin
    dv.update(ObjDb.new(id).group)
  rescue SelectID
  end
else
  raise "NO ID in Stat"
end
puts JSON.dump(dv.convert(stat))
