#!/usr/bin/ruby
require "libappsl"
require "libfrmsl"

ENV['VER']||='init/'
Msg.getopts("l")
alist=App::Slist.new
flist=Frm::Slist.new
begin
  ARGV.each{|i|
    sleep 0.3
    alist[i]
    flist[i]
  }.empty? && alist[nil]
  sleep
rescue UserError
  Msg.usage('(opt) [id] ....',*$optlist)
end
