#!/usr/bin/ruby
require "libinsdb"
require "libappcl"
require "libprint"
require "libshell"

id=ARGV.shift
host=ARGV.shift
begin
  adb=InsDb.new(id).cover_app
  ac=AppCl.new(adb,host)
rescue SelectID
  warn "Usage: appcl [id] (host)"
  Msg.exit
end
pri=Print.new(adb,ac.view)
Shell.new(ac.prompt,ac.commands){|cmd|
  ac.exe(cmd)||pri
}
