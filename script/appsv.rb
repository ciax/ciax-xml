#!/usr/bin/ruby
require "libappsv"

ENV['VER']||='init/'
Msg.getopts("l")
alist=App::List.new{|id,adb,fdb|
  App::Sv.new(adb,fdb,'localhost')
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
