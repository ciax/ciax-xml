#!/usr/bin/ruby
require "json"
require "libview"

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
elsif type=view['class']
  require "libobjdb"
  db=ObjDb.new(obj,type)
else
  raise "NO ID in View"
end
opt.split('').each{|s|
  case s
  when 'l'
    view.add_label(db)
  when 'g'
    view.add_arrange(db)
  when 's'
    view.init_sym(db).upd
  end
}
puts JSON.dump(view)
