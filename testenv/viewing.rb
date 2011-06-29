#!/usr/bin/ruby
require "json"
require "libview"

abort "Usage: viewing (-lgs) (obj) < [file]" if STDIN.tty?

obj=ARGV.shift
opt='als'
if (/^-/ === obj)
  opt=obj.delete('-')
  obj=ARGV.shift
end
str=STDIN.gets(nil) || exit
view=View.new(JSON.load(str))
if type=view['frame']
  require "libfrmdb"
  db=FrmDb.new(type)
elsif type=view['class']
  require "libobjdb"
  db=ObjDb.new(obj,type)
else
  raise "NO ID in View"
end
view.add(db,opt)
puts JSON.dump(view)
