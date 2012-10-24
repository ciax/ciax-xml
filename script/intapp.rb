#!/usr/bin/ruby
require "libapplist"
require "libfrmlist"

Msg.getopts("cfh:lts")
aint=App::List.new
fint=Frm::List.new
id=ARGV.shift
begin
  int=aint
  ARGV.each{|i| sleep 0.3;aint[i] }
  sleep if $opt["s"]
  while cmd=int[id].shell
    case cmd
    when /app/
      int=aint
    when /frm/
      int=fint
    else
      id=cmd
    end
  end
  rescue UserError
  Msg.usage('(opt) [id] ...',*$optlist)
end
