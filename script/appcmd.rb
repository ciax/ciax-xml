#!/usr/bin/ruby
require "libclsdb"
require "libappcmd"

cls,*cmd=ARGV
begin
  cdb=ClsDb.new(cls)
  cc=ClsCmd.new(cdb)
  cc.setcmd(cmd).cmdset.each{|cmd| p cmd}
rescue UserError
  abort "Usage: appcmd [class] [cmd] (par)\n#{$!}"
end
