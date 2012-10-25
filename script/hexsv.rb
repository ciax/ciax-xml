#!/usr/bin/ruby
require "libappsl"
require "libhexpack"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
alist=App::Slist.new{|obj,id|
  obj.extend(HexPack).ext_logging(id)
}
begin
  ARGV.each{|i|
    sleep 0.3
    alist[i]
  }.empty? && alist[nil]
  sleep
rescue UserError
  Msg.usage('(opt) [id] ....',*$optlist)
end
