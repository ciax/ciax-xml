#!/usr/bin/ruby
require "libappsl"
require "libhexpack"

Msg.getopts("h:s")
id=ARGV.shift
begin
  aint=App::Slist.new[id]
rescue UserError
  Msg.usage("(opt) [id]",*$optlist)
end
aint.extend(HexPack).ext_logging(id)
if $opt["s"]
  sleep
else
  aint.shell
end
