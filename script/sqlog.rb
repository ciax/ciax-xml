#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libcommand"
require "libfrmrsp"
require "libapprsp"
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
  stat=App::Stat.new.extend(App::Rsp).init(adb,field)
  stat.extend(SqLog::Stat)
  if opt['i'] # Initial
    stat.create
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
          stat.upd
          $stderr.print "."
        rescue
          $stderr.print $! if opt['v']
          $stderr.print "x"
        end
      end
    }
  end
  puts stat.sql
else
  fdb=adb.cover_frm
  ver=fdb['frm_ver']
  cobj=Command.new(fdb[:cmdframe])
  field.extend(Frm::Rsp).init(fdb,cobj)
  field.extend(SqLog::Stat)
  if opt['i'] # Initial
    field.create
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
  puts field.sql
end
