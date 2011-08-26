#!/usr/bin/ruby
require "libappdb"
require "libappcmd"

app,*cmd=ARGV
begin
  cdb=AppDb.new(app)
  ac=AppCmd.new(cdb)
  ac.setcmd(cmd).cmdset.each{|cmd| p cmd}
rescue UserError
  abort "Usage: appcmd [app] [cmd] (par)\n#{$!}"
end
