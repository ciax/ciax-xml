#!/usr/bin/ruby
require "liblocdb"
require "libcmdext"
require "libfrmrsp"
require "libapprsp"
require 'libstatus'
require "libsqlog"
require 'json'

Msg::GetOpts.new("t",{"i"=>"init table","v"=>"verbose","a"=>"app output"})
id = ARGV.shift
begin
  ldb=Loc::Db.new.set(id)
  field=Field::Var.new
rescue UserError
  $opt.usage("(opt) [id] (frmlog|fldlog)")
  # input format 'sqlite3 -header'
end
if $opt['a']
  adb=ldb[:app]
  stat=Status::Var.new.ext_file(adb['site_id'])
  stat.ext_rsp(field,adb[:status])
  stat.ext_sqlog($opt['t']&&"test")
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
  fdb=ldb[:frm]
  field.ext_file(fdb['site_id'])
  ver=fdb['version']
  cobj=Command.new
  cobj.add_extdom(fdb)
  field.ext_rsp(cobj,fdb)
  stat.ext_sqlog($opt['t']&&"test")
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
