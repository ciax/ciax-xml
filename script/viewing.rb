#!/usr/bin/ruby
require "json"
require "libview"
require "libcache"

abort "Usage: viewing (-als) (obj) < [status_file]" if STDIN.tty?

opt,arg=ARGV.partition{|s| /^-/ === s}
opt=opt.empty? ? 'als' : opt.join('')
obj=arg.first

while STDIN.gets
  stat=JSON.load($_)
  if type=stat['frame']
    require "libfrmdb"
    db=Cache.new("fdb",type){FrmDb.new(type)}
  elsif type=stat['class']
    require "libobjdb"
    db=Cache.new("odb",obj){ObjDb.new(obj,type)}
  else
    raise "NO Type ID in View"
  end
  view=View.new(stat)
  view.opt(opt,db[:status]).upd
  puts JSON.dump(view)
end
