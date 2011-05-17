#!/usr/bin/ruby
require "json"
require "libsym"
require "libsymdb"
require "libview"


abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

view=View.new(JSON.load(gets(nil)))
if frm=view['frame']
  require "libfrmdb"
  db=FrmDb.new(frm)
elsif cls=view['class']
  require "libobjdb"
  db=ObjDb.new(cls,view['id'])
else
  raise "NO ID in Status"
end
sdb=SymDb.new
sdb.update(db[:symtbl])
sym=Sym.new(sdb,db[:status][:symbol])
res=sym.convert(view)
puts JSON.dump(res)
