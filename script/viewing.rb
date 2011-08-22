#!/usr/bin/ruby
require "json"
require "libview"

abort "Usage: viewing (-als) (obj) < [status_file]" if STDIN.tty?

opt,arg=ARGV.partition{|s| /^-/ === s}
opt=opt.empty? ? 'als' : opt.join('')
obj=arg.first

while STDIN.gets
  stat=JSON.load($_)
  if type=stat['frame']
    require "libfrmdb"
    db=FrmDb.new(type)
  elsif type=stat['class']
    require "libclsdb"
    require "libobjdb"
    cdb=ClsDb.new(type)
    db=ObjDb.new(obj).cover(cdb)
  else
    raise "NO Type ID in View"
  end
  view=View.new(stat)
  view.opt(opt,db[:status]).upd
  puts JSON.dump(view)
end
