#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

Msg.getopts("h:s")
id=ARGV.shift
begin
  aint=App::List.new[id]
rescue UserError
  Msg.usage("(opt) [id]",*$optlist)
end
aint.extend(HexPack)
if $opt["s"]
  aint.server
  sleep
else
  aint.shell
end
