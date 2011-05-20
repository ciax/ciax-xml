#!/usr/bin/ruby
require "json"
require "libview"
require "liblabel"

abort "Usage: labeling (obj) < [file]" if STDIN.tty? && ARGV.size < 1

str=STDIN.gets(nil) || exit
view=View.new(JSON.load(str))
if type=view['frame']
  require "libfrmdb"
  db=FrmDb.new(type)
elsif type=view['class']
  require "libobjdb"
  db=ObjDb.new(ARGV.shift,type)
else
  raise "NO ID in View"
end
label=Label.new(db.status[:label])
puts JSON.dump(view.convert('label',label))
