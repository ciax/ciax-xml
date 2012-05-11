#!/usr/bin/ruby
require "libmcrsh"

id=ARGV.shift
ARGV.clear
begin
  mm=Mcr::Sh.new(id)
rescue SelectID
  Msg.usage("[mcr] # (ACT=n)")
end
mm.shell
