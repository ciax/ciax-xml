#!/usr/bin/ruby
require "libinsdb"
require "libcommand"
require "libfrmrsp"
require "libapprsp"
require 'libstatus'
require "libsqlog"
require 'json'

Msg.getopts("ivfa",{"v"=>"verbose","i"=>"init table"})
id = ARGV.shift
begin
  idb=Ins::Db.new(id)
  adb=idb.cover_app
  field=Field::Var.new
rescue UserError
  Msg.usage("(opt) [id] (frmlog|fldlog)",
            "* input format 'sqlite3 -header'",*$optlist)
end
if $opt['a']
  stat=Status::Var.new.ext_file(adb)
  stat.ext_rsp(field)
  stat.extend(SqLog::Var)
  if $opt['i'] # Initial
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
          $stderr.print $! if $opt['v']
          $stderr.print "x"
        end
      end
    }
  end
  puts stat.sql
else
  fdb=adb.cover_frm
  field.ext_file(fdb)
  ver=fdb['frm_ver']
  cobj=Command.new(fdb[:cmdframe])
  field.ext_rsp(cobj)
  field.extend(SqLog::Var)
  if $opt['i'] # Initial
    field.create
  else
    readlines.grep(/#{id}:#{ver}:rcv/).each{|str|
      begin
        field.upd_logline(str)
        $stderr.print "."
      rescue
        $stderr.print $! if $opt['v']
        $stderr.print "x"
        next
      end
    }
    $stderr.puts
  end
  puts field.sql
end
