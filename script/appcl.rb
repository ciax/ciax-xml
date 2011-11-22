#!/usr/bin/ruby
require "libinsdb"
require "libappcl"
require "libprint"
require "libshell"

id=ARGV.shift
host=ARGV.shift
begin
  cli=AppCl.new(id,host)
rescue SelectID
  warn "Usage: appcl [id] (host)"
  Msg.exit
end
pri=Print.new(cli.adb,cli.view)
Shell.new(cli.prompt){|cmd|
  cli.exe(cmd)||pri
}
