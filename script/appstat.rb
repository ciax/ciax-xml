#!/usr/bin/ruby
require "libappdb"
require "libappstat"
require "libfield"
require "libview"

app=ARGV.shift
ARGV.clear

begin
  adb=AppDb.new(app)
  str=gets(nil) || exit
  field=Field.new.update_j(str)
  view=View.new(field['id'],adb[:status]).update({'app_type' => app })
  as=AppStat.new(adb,view['stat']).upd(field)
  print view.upd.to_j
rescue RuntimeError
  abort "Usage: appstat [app] < field_file\n#{$!}"
end
