#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmlist"

$opt=ARGV.getopts("fdtsh:")
fint=Frm::List.new
id=ARGV.shift
begin
  int=fint[id]
  ARGV.each{|i| fint[i] }
  sleep if $opt["s"]
  int=fint[id] while id=int.shell
rescue UserError
  Msg.usage("(-sfd) (-h host) [id] ...",
            "-f:client",
            "-s:server","-d:dummy")
end
