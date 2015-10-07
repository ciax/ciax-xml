#!/usr/bin/ruby
require 'libinsdb'
require 'libfrmcmd'
require 'libfrmrsp'
require 'libapprsp'
require 'libstatus'
require 'libsqlog'
require 'liblogging'
# Convert Stream Log in SqLog to App::Staus;
module CIAX
  OPT.parse('t', 'v' => 'verbose')
  begin
    fail(InvalidID, '') if STDIN.tty? && ARGV.size < 1
    ldb = Ins::Db.new
    field = Frm::Field.new
    stat = App::Status.new
    sqlog = SqLog::Upd.new(stat, OPT['t'] && 'test')
    fobj = nil
    site_id = nil
    logline = ['begin;']
    readlines.grep(/rcv/).each do|str|
      hash = Logging.set_logline(str)
      if !site_id
        site_id = hash['id']
        ldb.set(hash['id'])
        Msg.msg('Initialize', 3)
        fdb = ldb[:frm]
        fobj = Frm::Command.new(Config.new.update(db: fdb))
        field.ext_rsp(site_id, fdb)
        adb = ldb[:app]
        stat.ext_rsp(site_id, adb, field)
      elsif site_id != hash['id']
        next
      end
      begin
        ent = fobj.set_cmd(hash['cmd'].split(':'))
        field.rcv(ent) { hash }.upd
        stat.upd
        logline << sqlog.upd
        Msg.progress
      rescue
        $stderr.print $ERROR_INFO if OPT['v']
        Msg.progress(false)
      end
    end
    logline << 'commit;'
    $stderr.puts
    puts logline.join("\n")
  rescue InvalidID
    OPT.usage('(opt) [stream_log]')
    # input format 'sqlite3 -header'
  end
end
