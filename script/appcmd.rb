#!/usr/bin/ruby
require "libappdb"
require "libappcmd"

app,*cmd=ARGV
begin
  adb=AppDb.new(app)
  ac=AppCmd.new(adb)
  ac.setcmd(cmd).cmdset.each{|cmd| p cmd}
rescue UserError
  abort "Usage: appcmd [app] [cmd] (par)\n#{$!}"
end
