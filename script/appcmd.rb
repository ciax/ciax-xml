#!/usr/bin/ruby
require "libappdb"
require "libappcmd"

cls,*cmd=ARGV
begin
  cdb=AppDb.new(cls)
  ac=AppCmd.new(cdb)
  ac.setcmd(cmd).cmdset.each{|cmd| p cmd}
rescue UserError
  abort "Usage: appcmd [app] [cmd] (par)\n#{$!}"
end
