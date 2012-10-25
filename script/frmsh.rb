#!/usr/bin/ruby
require "libfrmsl"

ENV['VER']||='init/'
Msg.getopts("tl")
fint=Frm::Slist.new
id=ARGV.shift
begin
  begin
    int=fint[id]
  end while id=int.shell
rescue UserError
  Msg.usage("(opt) [id]",*$optlist)
end
