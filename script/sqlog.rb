#!/usr/bin/ruby
require "json"
require "libinsdb"
require "libfield"
require "libfrmrsp"
require "libappstat"
require "libsql"

id = ARGV.shift
begin
  idb=InsDb.new(id).cover_app.cover_frm
  par=Param.new(idb[:cmdframe])
  field=Field.new(id)
  fr=FrmRsp.new(idb,par,field)
  as=AppStat.new(idb[:status])
  sql=Sql.new(id)
rescue UserError
  warn "Usage: #{$0} [id] < logfile"
  Msg.exit
end

STDIN.readlines.grep(/rcv/).each{|str|
  ary=str.split("\t")
  time=Time.at(ary.shift.to_f)
  cmd=ary.shift.split(':')
  cmd.shift
  begin
    par.set(cmd)
    fr.setrsp{[time,eval(ary.shift)]}
    sql.upd(as.conv(field))
    $stderr.print "."
  rescue
    next
  end
}
puts sql.to_s
