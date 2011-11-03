#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libparam"
require "libfrmrsp"
require "libappstat"
require "libsql"

opt=ARGV.getopts("i")
id = ARGV.shift
begin
  adb=InsDb.new(id).cover_app
  fdb=adb.cover_frm
  par=Param.new(fdb[:cmdframe])
  fr=FrmRsp.new(fdb,par)
  as=AppStat.new(adb,fr.field)
  sql=Sql.new(id,as)
rescue UserError
  warn "Usage: #{$0} (-i) [id] < logfile"
  Msg.exit
end
if opt['i']
  sql.create
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
puts sql.to_s
