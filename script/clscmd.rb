#!/usr/bin/ruby
require "libclsdb"
require "libclscmd"

cls=ARGV.shift
cmd=ARGV
begin
  cdbc=ClsDb.new(cls).cdbc
  cc=ClsCmd.new(cdbc,cls)
  cc.setcmd(cmd).statements.each{|c| p c}
rescue UserError
  abort "Usage: clscmd [class] [cmd] (par)\n#{$!}"
end
