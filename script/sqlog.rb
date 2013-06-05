#!/usr/bin/ruby
require "liblocdb"
require "libfrmcmd"
require "libfrmrsp"
require "libapprsp"
require 'libstatus'
require "libsqlog"
require 'liblogging'


Msg::GetOpts.new("t",{"v"=>"verbose"})
begin
  raise(InvalidID,'') if STDIN.tty? && ARGV.size < 1
  ldb=Loc::Db.new
  field=Field::Var.new
  stat=Status::Var.new
  fgrp=nil
  site_id=nil
  readlines.grep(/rcv/).each{|str|
    hash=Logging.set_logline(str)
    if !site_id
      site_id=hash['id']
      ldb.set(hash['id'])
      Msg.warn("Initialize")
      fdb=ldb[:frm]
      fgrp=Frm::ExtGrp.new(fdb)
      field.ext_file(fdb['site_id']).load
      field.ext_rsp(fdb)
      adb=ldb[:app]
      stat.ext_file(adb['site_id'])
      stat.ext_rsp(field,adb[:status])
      stat.ext_sqlog($opt['t']&&"test")
    elsif site_id != hash['id']
      next
    end
    begin
      item=fgrp.setcmd(hash['cmd'].split(':'))
      field.upd(item){hash}
      stat.upd
      Msg.progress
    rescue
      $stderr.print $! if $opt['v']
      Msg.progress(false)
    end
  }
  $stderr.puts
  puts stat.sql
rescue InvalidID
  $opt.usage("(opt) [stream_log]")
  # input format 'sqlite3 -header'
end
