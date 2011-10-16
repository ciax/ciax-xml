#!/usr/bin/ruby
require "libinsdb"
require "libappcl"
require "libprint"
require "libshell"

id=ARGV.shift
host=ARGV.shift||'localhost'
begin
  adb=InsDb.new(id).cover_app
rescue SelectID
  warn "Usage: appcl [id] (host)"
  Msg.exit
end
cli=AppCl.new(adb,host)
pri=Print.new(adb[:status],cli.view)
Shell.new(cli.prompt){|cmd|
  cli.upd(cmd).message||pri
}
