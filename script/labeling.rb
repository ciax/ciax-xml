#!/usr/bin/ruby
require "json"
require "libview"
require "liblabel"

abort "Usage: labeling [file]" if STDIN.tty? && ARGV.size < 1

view=View.new(JSON.load(gets(nil)))
if type=view['frame']
  require "libfrmdb"
  fdb=FrmDb.new(type)
  label=Label.new(fdb[:status][:label])
elsif type=view['class']
  require "libobjdb"
  cdb=ObjDb.new(type,view['id'])
  label=Label.new(cdb[:status][:label])
else
  raise "NO ID in View"
end
puts JSON.dump(view.convert('label',label))
