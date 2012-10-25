#!/usr/bin/ruby
require "libappsl"

ENV['VER']||='init/'
Msg.getopts("l")
alist=App::Slist.new
begin
  ARGV.each{|i|
    sleep 0.3
    alist[i]
  }.empty? && alist[nil]
  sleep
rescue UserError
  Msg.usage('(opt) [id] ....',*$optlist)
end
