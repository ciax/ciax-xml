#!/usr/bin/ruby
require "libfrmlist"

Msg.getopts("ch:tls")
fint=Frm::List.new(ENV['PROJ'])
id=ARGV.shift
begin
  int=fint[id]
  ARGV.each{|i| fint[i] }
  sleep if $opt["s"]
  int=fint[id] while id=int.shell
rescue UserError
  Msg.usage("(opt) [id] ...",*$optlist)
end
