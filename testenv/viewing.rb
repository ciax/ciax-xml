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
stat=JSON.load(str)
if type=stat['frame']
  require "libfrmdb"
  db=FrmDb.new(type)
elsif type=stat['class']
  require "libobjdb"
  db=ObjDb.new(obj,type)
else
  raise "NO ID in View"
end
view=View.new(stat,db)
view.opt(opt).upd
puts JSON.dump(view)
