#!/usr/bin/ruby
require "json"
require "libview"
require "libgroup"

abort "Usage: grouping [file]" if STDIN.tty? && ARGV.size < 1

view=View.new(JSON.load(gets(nil)))
if type=view['frame']
  require "libfrmdb"
  fdb=FrmDb.new(type)
  group=Group.new(fdb.group)
elsif type=view['class']
  require "libobjdb"
  id=view['id']
  cdb=ObjDb.new(type,id)
  group=Group.new(cdb[:status][:group])
else
  raise "NO ID in Status"
end
puts JSON.dump(view.convert('group',group))
