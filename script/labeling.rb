#!/usr/bin/ruby
require "json"
require "libview"
require "liblabel"
require "libobjdb"

abort "Usage: labeling [file]" if STDIN.tty? && ARGV.size < 1

view=View.new(JSON.load(gets(nil)))
if type=view['frame']
  require "libfrmdb"
  fdb=FrmDb.new(type)
  label=Label.new(fdb.label)
elsif type=view['class']
  require "libclsdb"
  id=view['id']
  cdb=ClsDb.new(type)
  label=Label.new(cdb.label)
  label.update(ObjDb.new(id).label)
else
  raise "NO ID in View"
end
puts JSON.dump(view.convert('label',label))
