#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libcommand"
require "libfrmrsp"
require "libappstat"
require 'librview'
require "libsql"

opt=ARGV.getopts("ia")
id = ARGV.shift
begin
  idb=InsDb.new(id)
  adb=idb.cover_app
rescue UserError
  Msg.usage("(-ai) [id] (logfile) ( < sqlite3 -line id)","-i:init table","-a:app stat")
end
if opt['a']
  field=Field.new
  stat=AppStat.new(adb,field)
  sql=Sql.new(id,adb['app_ver'],stat)
  if opt['i'] # Initial
    sql.ini
  else
    readlines.each{|str|
      if /^$/ =~ str
        begin
          stat.upd
          sql.upd
          $stderr.print "."
        rescue
          $stderr.print "x"
          next
        end
      else
        k,v=str.split("=").map{|i| i.strip}
        field[k]=v
      end
    }
  end
else
  fdb=adb.cover_frm
  cobj=Command.new(fdb[:cmdframe])
  field=FrmRsp.new(fdb,cobj)
  ver=fdb['frm_ver']
  sql=Sql.new(id,ver,field)
  if opt['i'] # Initial
    sql.ini
  else
    readlines.grep(/##{ver}:rcv/).each{|str|
      begin
        field.upd_logline(str)
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
