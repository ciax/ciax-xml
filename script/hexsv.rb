#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
alist=App::List.new{|id,adb,fdb|
  App::Sv.new(adb,fdb,'localhost').extend(HexPack).ext_logging(id)
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
