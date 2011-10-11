#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libparam"
require "libfield"
require "libfrmrsp"
require "libappstat"
require "libsql"

opt=ARGV.getopts("i")
id = ARGV.shift
begin
  adb=InsDb.new(id).cover_app
  fdb=adb.cover_frm
  par=Param.new(fdb[:cmdframe])
  field=Field.new(id)
  fr=FrmRsp.new(fdb,par,field)
  as=AppStat.new(adb,field)
  sql=Sql.new(id,as)
rescue UserError
  warn "Usage: #{$0} (-i) [id] < logfile"
  Msg.exit
end
if opt['i']
  sql.create
else
  STDIN.readlines.grep(/rcv/).each{|str|
    ary=str.split("\t")
    time=Time.at(ary.shift.to_f)
    cmd=ary.shift.split(':')
    cmd.shift
    begin
      par.set(cmd)
      fr.upd{[time,eval(ary.shift)]}
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
