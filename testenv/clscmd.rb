#!/usr/bin/ruby
require "libclsdb"
require "libclscmd"

cls,*cmd=ARGV
begin
  cdb=ClsDb.new(cls)
  cc=ClsCmd.new(cdb)
  cc.setcmd(cmd).statements.each{|c| p c}
rescue UserError
  abort "Usage: clscmd [class] [cmd] (par)\n#{$!}"
end
