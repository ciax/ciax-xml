#!/usr/bin/ruby
require "libmcrint"

id=ARGV.shift
ARGV.clear
begin
  mm=Mcr::Int.new(id)
rescue SelectID
  Msg.usage("[mcr] # (ACT=n)")
end
mm.shell
