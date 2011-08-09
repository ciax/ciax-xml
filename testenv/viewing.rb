#!/usr/bin/ruby
require "json"
require "libviewopt"

abort "Usage: viewing (-als) (obj) < [status_file]" if STDIN.tty?

opt,arg=ARGV.partition{|s| /^-/ === s}
opt=opt.empty? ? 'als' : opt.join('')
obj=arg.first

str=STDIN.gets(nil) || exit
stat=JSON.load(str)
if type=stat['frame']
  require "libfrmdb"
  db=FrmDb.new(type)
elsif type=stat['class']
  require "libobjdb"
  db=ObjDb.new(obj,type)
else
  raise "NO Type ID in View"
end
view=ViewOpt.new(db,stat)
view.opt(opt).upd
if opt.include?('p')
  puts view
else
  puts JSON.dump(view)
end
