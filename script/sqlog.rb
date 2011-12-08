#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libcommand"
require "libfrmrsp"
require "libappstat"
require 'librview'
require "libsql"

opt=ARGV.getopts("isa:")
id = ARGV.shift
begin
  idb=InsDb.new(id)
rescue UserError
  Msg.usage "(-is) (-a key) [id] < logfile"
end
if opt['s'] # From remote
  stat=Rview.new(id).load['stat']
  sql=Sql.new(id,idb['version'],stat).upd
else
  adb=idb.cover_app
  fdb=adb.cover_frm
  cobj=Command.new(fdb[:cmdframe])
  field=FrmRsp.new(fdb,cobj)
  stat=AppStat.new(adb,field)
  sql=Sql.new(id,adb['version'],stat)
  if opt['i'] # Initial
    sql.ini
  elsif key=opt['a'] # Alter
    sql.add(key)
  else
    STDIN.readlines.grep(/rcv/).each{|str|
      begin
        field.upd_logline(str)
        stat.upd
        sql.upd
        $stderr.print "."
      rescue
        $stderr.print "x"
        next
      end
    }
    $stderr.puts
  end
end
puts sql.to_s
