#!/usr/bin/ruby
require "json"
require "libsym"
require "libsymdb"
require "libview"


abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

view=View.new(JSON.load(gets(nil)))
sdb=SymDb.new
if frm=view['frame']
  require "libfrmdb"
  dba=[FrmDb.new(frm)]
elsif cls=view['class']
  require "libclsdb"
  require "libobjdb"
  dba=[ClsDb.new(cls),ObjDb.new(view['id'])]
else
  raise "NO ID in Status"
end
ref={}
dba.each{|db|
  ref.update(db.symref)
  sdb.update(db.table)
}
sym=Sym.new(sdb,ref)
res=sym.convert(view)
puts JSON.dump(res)
