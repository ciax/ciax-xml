#!/usr/bin/ruby
require "json"
require "libview"
require "liblabel"

abort "Usage: labeling [file]" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
view=View.new(JSON.load(str))
if type=view['frame']
  require "libfrmdb"
  fdb=FrmDb.new(type)
  label=Label.new(fdb.status[:label])
elsif type=view['class']
  require "libobjdb"
  cdb=ObjDb.new(view['id'],type)
  label=Label.new(cdb.status[:label])
else
  raise "NO ID in View"
end
puts JSON.dump(view.convert('label',label))
