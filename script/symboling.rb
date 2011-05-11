#!/usr/bin/ruby
require "json"
require "libsym"
require "libmods2q"
include S2q

abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

stat=s2q(JSON.load(gets(nil)))
if frm=stat['header']['frame']
  require "libfrmdb"
  db=FrmDb.new(frm)
elsif cls=stat['header']['class']
  require "libclsdb"
  db=ClsDb.new(cls)
else
  raise "NO ID in Status"
end
sym=Sym.new
sym.update(db)
res=sym.convert(stat)
puts JSON.dump(res)
