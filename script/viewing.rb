#!/usr/bin/ruby
require "json"
require "libview"
require "liblabel"
require "libgroup"
require "libsym"
require "libsymdb"

abort "Usage: viewing (-lgs) (obj) < [file]" if STDIN.tty?

obj=ARGV.shift
opt='lgs'
if (/^-/ === obj)
  opt=obj.delete('-')
  obj=ARGV.shift
end
str=STDIN.gets(nil) || exit
view=View.new(JSON.load(str))
if type=view['frame']
  require "libfrmdb"
  db=FrmDb.new(type)
  opt.delete!('g')
elsif type=view['class']
  require "libobjdb"
  db=ObjDb.new(obj,type)
else
  raise "NO ID in View"
end
opt.split('').each{|s|
  case s
  when 'l'
    Label.new(db.status[:label]).convert(view)
  when 'g'
    Group.new(db.status[:group]).convert(view)
  when 's'
    sdb=SymDb.new
    sdb.update(db.symtbl)
    sym=Sym.new(sdb,db.status[:symbol])
    view=sym.convert(view)
  end
}
puts JSON.dump(view)
