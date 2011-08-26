#!/usr/bin/ruby
require "json"
require "libview"

abort "Usage: viewing (-als) (obj) < [status_file]" if STDIN.tty?

opt,arg=ARGV.partition{|s| /^-/ === s}
opt=opt.empty? ? 'als' : opt.join('')
obj=arg.first

while STDIN.gets
  stat=JSON.load($_)
  if type=stat['frm_type']
    require "libfrmdb"
    db=FrmDb.new(type)
  elsif type=stat['app_type']
    require "libclsdb"
    require "libobjdb"
    db=ClsDb.new(type) << ObjDb.new(obj)
  else
    raise "NO Type ID in View"
  end
  view=View.new(stat)
  view.opt(opt,db[:status]).upd
  puts JSON.dump(view)
end
