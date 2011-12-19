#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libcommand"
require "libfrmrsp"
require "libappstat"
require 'librview'
require "libsql"

opt=ARGV.getopts("iav")
id = ARGV.shift
begin
  idb=InsDb.new(id)
  adb=idb.cover_app
rescue UserError
  Msg.usage("(-aiv) [id] (logfile|sql output)",
            "-v:verbose",
            "-i:init table",
            "-a:app stat, need -line option in sqlite3")
end
if opt['a']
  field=Field.new
  stat=AppStat.new(adb,field)
  field.updlist << proc{ stat.upd }
  sql=Sql.new('stat',id,adb['app_ver'],stat)
  field.updlist << proc{ sql.upd }
  if opt['i'] # Initial
    sql.ini
  else
    readlines.each{|str|
      if /^$/ =~ str
        begin
          field.upd
          $stderr.print "."
        rescue
          $stderr.print $! if opt['v']
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
  ver=fdb['frm_ver']
  cobj=Command.new(fdb[:cmdframe])
  field=FrmRsp.new(fdb,cobj)
  sql=Sql.new('field',id,ver,field)
  field.updlist << proc{ sql.upd }
  if opt['i'] # Initial
    sql.ini
  else
    readlines.grep(/#{id}:#{ver}:rcv/).each{|str|
      begin
        field.upd_logline(str)
        $stderr.print "."
      rescue
        $stderr.print $! if opt['v']
        $stderr.print "x"
        next
      end
    }
    $stderr.puts
  end
end
puts sql.to_s
