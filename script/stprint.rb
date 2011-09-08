#!/usr/bin/ruby
require "json"
require "libappdb"
require "libobjdb"
require "libprint"

abort "Usage: stprint < [stat_file]" if STDIN.tty?
while gets
  stat=JSON.load($_)
  db=ObjDb.new(stat['id']).cover_app
  puts Print.new(db[:status]).upd(stat)
end
