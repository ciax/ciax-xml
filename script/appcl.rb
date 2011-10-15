#!/usr/bin/ruby
require "libinsdb"
require "libclient"
require "librview"
require "libprint"
require "libparam"
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
view=Rview.new(id,host)
prt=Print.new(adb[:status],view)
par=Param.new(adb[:command])
Shell.new(cli.prompt){|cmd|
  case msg=cli.upd(cmd).message
  when nil
    view.upd
    prt
  when /CMD/
    par.set(cmd)
  else
    msg
  end
}
