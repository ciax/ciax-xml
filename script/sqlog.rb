#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libcommand"
require "libfrmrsp"
require "libappval"
require 'libstat'
require "libsqlog"
require 'json'

opt=ARGV.getopts("iafv")
id = ARGV.shift
begin
  idb=InsDb.new(id)
  adb=idb.cover_app
  field=Field.new
rescue UserError
  Msg.usage("(-aiv) [id] (frmlog|fldlog)",
            "-v:verbose",
            "-i:init table",
            "-f:frm level(default)",
            "-a:app level(input format 'sqlite3 -header')")
end
if opt['a']
  val=App::Val.new(adb,field)
  sql=SqLog.new('value',id,adb['app_ver'],val)
  if opt['i'] # Initial
    sql.ini
  else
    index=nil
    readlines.each{|str|
      ary=str.split('|')
      if /^time/ =~ str
        index=ary
      else
        hash={}
        begin
          index.each{|i|
            hash[i]=ary.shift
          }
          field.update(hash)
          val.upd
          sql.upd
          $stderr.print "."
        rescue
          $stderr.print $! if opt['v']
          $stderr.print "x"
        end
      end
    }
  end
else
  fdb=adb.cover_frm
  ver=fdb['frm_ver']
  cobj=Command.new(fdb[:cmdframe])
  fr=Frm::Rsp.new(fdb,cobj,field)
  sql=SqLog.new('field',id,ver,field)
  if opt['i'] # Initial
    sql.ini
  else
    readlines.grep(/#{id}:#{ver}:rcv/).each{|str|
      begin
        fr.upd_logline(str) && sql.upd
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
