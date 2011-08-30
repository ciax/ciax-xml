#!/usr/bin/ruby
require "json"
require "libview"
require "libappdb"
require "libobjdb"

abort "Usage: viewing (-als) (obj) < [status_file]" if STDIN.tty?

opt,arg=ARGV.partition{|s| /^-/ === s}
opt=opt.empty? ? 'als' : opt.join('')
obj=arg.first

while STDIN.gets
  stat=JSON.load($_)
  if type=stat['app_type']
    db=AppDb.new(type) << ObjDb.new(obj)
  else
    raise "NO Type ID in View"
  end
  view=View.new(stat)
  view.opt(opt,db[:status]).upd
  puts JSON.dump(view)
end
