#!/usr/bin/ruby
require "libsitedb"
require "libfrmcmd"
require "libfrmrsp"
require "libapprsp"
require 'libstatus'
require "libsqlog"
require 'liblogging'

module CIAX
  GetOpts.new("t",{"v"=>"verbose"})
  begin
    raise(InvalidID,'') if STDIN.tty? && ARGV.size < 1
    ldb=Loc::Db.new
    field=Frm::Field.new
    stat=App::Status.new
    sqlog=SqLog::Upd.new(stat,$opt['t']&&"test")
    fobj=nil
    site_id=nil
    logline=['begin;']
    readlines.grep(/rcv/).each{|str|
      hash=Logging.set_logline(str)
      if !site_id
        site_id=hash['id']
        ldb.set(hash['id'])
        Msg.msg("Initialize",3)
        fdb=ldb[:frm]
        fobj=Frm::Command.new(Config.new.update(:db =>fdb))
        field.ext_rsp(site_id,fdb)
        adb=ldb[:app]
        stat.ext_rsp(site_id,adb,field)
      elsif site_id != hash['id']
        next
      end
      begin
        ent=fobj.set_cmd(hash['cmd'].split(':'))
        field.rcv(ent){hash}.upd
        stat.upd
        logline << sqlog.upd
        Msg.progress
      rescue
        $stderr.print $! if $opt['v']
        Msg.progress(false)
      end
    }
    logline << 'commit;'
    $stderr.puts
    puts logline.join("\n")
  rescue InvalidID
    $opt.usage("(opt) [stream_log]")
    # input format 'sqlite3 -header'
  end
end
