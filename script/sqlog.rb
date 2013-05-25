#!/usr/bin/ruby
require "liblocdb"
require "libfrmcmd"
require "libfrmrsp"
require "libapprsp"
require 'libstatus'
require "libsqlog"
require 'liblogging'

def get_field(ldb,field)
  Msg.warn("Frame Initialize")
  fdb=ldb[:frm]
  ver=fdb['version']
  cobj=Command.new
  svdom=cobj.add_domain('sv')
  svdom['ext']=Frm::ExtGrp.new(fdb)
  field.ext_file(fdb['site_id'])
  field.ext_rsp(cobj,fdb)
  field
end

def get_stat(ldb,field,stat)
  Msg.warn("Application Initialize")
  adb=ldb[:app]
  stat.ext_file(adb['site_id'])
  stat.ext_rsp(field,adb[:status])
  stat.ext_sqlog($opt['t']&&"test")
  stat
end

Msg::GetOpts.new("t",{"v"=>"verbose"})
begin
  raise(InvalidID,'') if STDIN.tty? && ARGV.size < 1
  ldb=Loc::Db.new
  field=Field::Var.new
  stat=Status::Var.new
  readlines.grep(/rcv/).each{|str|
    hash=JSON.load(str)
    ldb.set(hash['id']) unless ldb.key?('id')
    get_field(ldb,field) unless Frm::Rsp === field
    get_stat(ldb,field,stat) unless App::Rsp === stat
    begin
      field.upd_logline(str)
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
