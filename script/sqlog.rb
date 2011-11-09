#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libparam"
require "libfrmrsp"
require "libappstat"
require "libsql"

opt=ARGV.getopts("ia:d:")
id = ARGV.shift
begin
  adb=InsDb.new(id).cover_app
  fdb=adb.cover_frm
  par=Param.new(fdb[:cmdframe])
  fr=FrmRsp.new(fdb,par)
  as=AppStat.new(adb,fr.field)
  sql=Sql.new(id,as)
rescue UserError
  warn "Usage: #{$0} (-i) (-a|d key,key) [id] < logfile"
  Msg.exit
end
if opt['i']
  sql.create
elsif keys=opt['a']
  sql.add(keys)
elsif keys=opt['d']
  sql.del(keys)
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
