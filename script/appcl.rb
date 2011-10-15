#!/usr/bin/ruby
require "libclient"
require "libinsdb"
require "libshell"

id=ARGV.shift
host=ARGV.shift||'localhost'
begin
  adb=InsDb.new(id).cover_app
rescue SelectID
  warn "Usage: appcl [id] (host)"
  Msg.exit
end
cli=Client.new(id,adb['port'],host)
pr=Print.new(adb[:status],cli.view)
par=Param.new(adb[:command])
Shell.new(cli.prompt){|cmd|
  case msg=cli.upd(cmd).message
  when nil
    pr
  when /CMD/
    par.set(cmd)
  else
    msg
  end
}
