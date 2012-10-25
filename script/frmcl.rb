#!/usr/bin/ruby
require "libfrmcl"

ENV['VER']||='init/'
Msg.getopts("h:")
fint=Frm::Clist.new($opt["h"])
id=ARGV.shift
begin
  begin
    int=fint[id]
  end while id=int.shell
rescue UserError
  Msg.usage("(opt) [id]",*$optlist)
end
