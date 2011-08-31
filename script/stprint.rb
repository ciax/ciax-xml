#!/usr/bin/ruby
require "json"
require "libappdb"
require "libobjdb"
require "libprint"

abort "Usage: stprint < [stat_file]" if STDIN.tty?
while gets
  stat=JSON.load($_)
  app=stat['app_type']
  db=AppDb.new(app)
  db << ObjDb.new(stat['id'])
  puts Print.new(db[:status],stat)
end
