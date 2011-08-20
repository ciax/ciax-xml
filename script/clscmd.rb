#!/usr/bin/ruby
require "libclsdb"
require "libclscmd"
require "libcache"

cls,*cmd=ARGV
begin
  cdb=ClsDb.new(cls)
  cc=ClsCmd.new(cdb)
  cc.setcmd(cmd).cmdset.each{|cmd| p cmd}
rescue UserError
  abort "Usage: clscmd [class] [cmd] (par)\n#{$!}"
end
