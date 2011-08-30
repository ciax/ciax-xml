#!/usr/bin/ruby
require "libview"
require "libappdb"
require "libobjdb"

abort "Usage: viewing (-als) (obj) < [view_file]" if STDIN.tty?

opt,arg=ARGV.partition{|s| /^-/ === s}
opt=opt.empty? ? 'als' : opt.join('')
obj=arg.first

while STDIN.gets
  view=View.new(obj).update_j($_)
  if type=view['app_type']
    db=AppDb.new(type)
    db << ObjDb.new(obj) if obj
  else
    raise "NO Type ID in View"
  end
  view.opt(opt,db[:status]).upd
  puts view.to_j
end
