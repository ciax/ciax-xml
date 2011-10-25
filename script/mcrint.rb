#!/usr/bin/ruby
require "libmcrdb"
require "libmcrobj"
require 'libshell'

id=ARGV.shift
ARGV.clear
begin
  mdb=McrDb.new(id)
  ac=McrObj.new(mdb)
rescue SelectID
  warn "Usage: #{$0} [mcr]"
  Msg.exit
end
Shell.new('mcr>'){|cmd|
  Thread.new{
    Thread.pass
    ac.mcr(cmd)
  } unless cmd.empty?
  ac
}
