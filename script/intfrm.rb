#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmlist"

Msg.getopts("ltsh:")
fint=Frm::List.new
id=ARGV.shift
begin
  int=fint[id]
  ARGV.each{|i| fint[i] }
  sleep if $opt["s"]
  int=fint[id] while id=int.shell
rescue UserError
  Msg.usage("(opt) [id] ...",*$optlist)
end
