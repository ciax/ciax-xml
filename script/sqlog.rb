#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfield"
require "libfrmrsp"
require "libappstat"
require "libsql"

opt=ARGV.getopts("i")
id = ARGV.shift
begin
  idb=InsDb.new(id).cover_app.cover_frm
  par=Param.new(idb[:cmdframe])
  field=Field.new(id)
  fr=FrmRsp.new(idb,par,field)
  as=AppStat.new(idb[:status],field,stat={})
  sql=Sql.new(stat,id)
rescue UserError
  warn "Usage: #{$0} (-i) [id] < logfile"
  Msg.exit
end
if opt['i']
  sql.create(idb[:status][:select].keys)
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
      next
    end
  }
end
puts sql.to_s
