#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libcommand"
require "libfrmrsp"
require "libappstat"
require 'librview'
require "libsql"
require 'json'

opt=ARGV.getopts("iafv")
id = ARGV.shift
begin
  idb=InsDb.new(id)
  adb=idb.cover_app
  field=Field.new
rescue UserError
  Msg.usage("(-aiv) [id] (logfile|jsonlog)",
            "-v:verbose",
            "-i:init table",
            "-f:frm level(default)",
            "-a:app level")
end
if opt['a']
  stat=AppStat.new(adb,field)
  field.at_save << proc{ stat.upd }
  sql=Sql.new('stat',id,adb['app_ver'],stat)
  field.at_save << proc{ sql.upd }
  if opt['i'] # Initial
    sql.ini
  else
    readlines.each{|str|
      begin
        field.update(JSON.load(str))
        $stderr.print "."
      rescue
        $stderr.print $! if opt['v']
        $stderr.print "x"
      end
    }
  end
else
  fdb=adb.cover_frm
  ver=fdb['frm_ver']
  cobj=Command.new(fdb[:cmdframe])
  fr=FrmRsp.new(fdb,cobj,field)
  sql=Sql.new('field',id,ver,field)
  field.at_save << proc{ sql.upd }
  if opt['i'] # Initial
    sql.ini
  else
    readlines.grep(/#{id}:#{ver}:rcv/).each{|str|
      begin
        fr.upd_logline(str)
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
