#!/usr/bin/ruby
require "libclient"
require "libinsdb"
require "libprint"
require "libshell"

id=ARGV.shift
host=ARGV.shift||'localhost'
begin
  adb=InsDb.new(id).cover_app
  cli=Client.new(adb,host)
rescue SelectID
  warn "Usage: appcl [id] (host)"
  Msg.exit
end
prt=Print.new(adb[:status],cli.view)
Shell.new(cli.prompt){|cmd|
  cli.upd(cmd) || prt
}
