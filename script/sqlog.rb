#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libparam"
require "libfrmrsp"
require "libappstat"
require 'librview'
require "libsql"

opt=ARGV.getopts("isa:")
id = ARGV.shift
begin
  idb=InsDb.new(id)
rescue UserError
  warn "Usage: #{$0} (-is) (-a key) [id] < logfile"
  Msg.exit
end
if opt['s']
  stat=Rview.new(id).load['stat']
  sql=Sql.new(id,stat).upd
else
  adb=idb.cover_app
  fdb=adb.cover_frm
  par=Param.new(fdb[:cmdframe])
  fr=FrmRsp.new(fdb,par)
  stat=AppStat.new(adb,fr.field)
  sql=Sql.new(id,stat)
  if opt['i']
    sql.ini
  elsif key=opt['a']
    sql.add(key)
  else
    STDIN.readlines.grep(/rcv/).each{|str|
      begin
        fr.upd_logline(str)
        as.upd
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
