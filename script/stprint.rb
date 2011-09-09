#!/usr/bin/ruby
require "json"
require "libappdb"
require "libobjdb"
require "libprint"

abort "Usage: stprint < [status_file]" if STDIN.tty?
while gets
  view=JSON.load($_)
  db=ObjDb.new(view['id']).cover_app
  puts Print.new(db[:status]).upd(view)
end
