#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmlist"

$opt=ARGV.getopts("fds")
id,$opt['h']=ARGV
begin
  fint=Frm::List.new{|int,devs|
    int.cmdlist.add_group('dev',"Change Device",devs)
  }
rescue UserError
  Msg.usage("(-sfd) [id] (host)",
            "-f:client",
            "-s:server","-d:dummy")
end
sleep if $opt["s"]
begin
  int=fint[id]
end while id=int.shell
