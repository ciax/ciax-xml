#!/usr/bin/ruby
require "libmcrman"

id=ARGV.shift
ARGV.clear
begin
  mm=Mcr::Man.new(id)
rescue SelectID
  Msg.usage("[mcr] # (ACT=n)")
end
mm.shell
