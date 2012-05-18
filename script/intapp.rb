#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libapplist"

Msg.getopts("cfh:lts")
aint=App::List.new
id=ARGV.shift
begin
  int=aint[id]
  ARGV.each{|i| sleep 0.3;aint[i] }
  sleep if $opt["s"]
  int=aint[id] while id=int.shell
rescue UserError
  Msg.usage('(opt) [id] ...',*$optlist)
end
