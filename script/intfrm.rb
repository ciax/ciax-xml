#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmlist"

$opt=ARGV.getopts("fds")
id,$opt['h']=ARGV
fint=Frm::List.new
begin
  begin
    int=fint[id]
    sleep if $opt["s"]
  end while id=int.shell
rescue UserError
  Msg.usage("(-sfd) [id] (host)",
            "-f:client",
            "-s:server","-d:dummy")
end
