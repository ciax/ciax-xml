#!/usr/bin/ruby
require "json"
require "libsym"
require "libsymdb"
require "libview"


abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
view=View.new(JSON.load(str))
if frm=view['frame']
  require "libfrmdb"
  db=FrmDb.new(frm)
elsif cls=view['class']
  require "libobjdb"
  db=ObjDb.new(view['id'],cls)
else
  raise "NO ID in Status"
end
sdb=SymDb.new
sdb.update(db.symtbl)
sym=Sym.new(sdb,db.status[:symbol])
res=sym.convert(view)
puts JSON.dump(res)
