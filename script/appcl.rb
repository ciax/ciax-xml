#!/usr/bin/ruby
require "libclient"
require "libinsdb"
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
Shell.new(cli.prompt){|cmd|
  cli.upd(cmd)
}
