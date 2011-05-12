#!/usr/bin/ruby
require "json"
require "libview"
require "libgroup"
require "libobjdb"

abort "Usage: grouping [file]" if STDIN.tty? && ARGV.size < 1

view=View.new(JSON.load(gets(nil)))
if type=view['frame']
  require "libfrmdb"
  fdb=FrmDb.new(type)
  group=Group.new(fdb.group)
elsif type=view['class']
  require "libclsdb"
  id=view['id']
  cdb=ClsDb.new(type)
  group=Group.new(cdb.group)
  begin
    group.update(ObjDb.new(id).group)
  rescue SelectID
  end
else
  raise "NO ID in Status"
end
puts JSON.dump(view.convert('group',group))
