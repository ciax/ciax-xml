#!/usr/bin/ruby
require "json"
require "libsym"
require "libview"

abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

view=View.new(JSON.load(gets(nil)))
if frm=view['frame']
  require "libfrmdb"
  db=FrmDb.new(frm)
elsif cls=view['class']
  require "libclsdb"
  db=ClsDb.new(cls)
else
  raise "NO ID in Status"
end
sym=Sym.new
sym.update(db)
res=sym.convert(view)
puts JSON.dump(res)
