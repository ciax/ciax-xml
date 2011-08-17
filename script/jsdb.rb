#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libsymdb"

abort "Usage: jsdb [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
odb=ObjDb.new(obj,cls)
sdb=SymDb.new.add(cls)
puts "OBJ=\"#{obj}\";"
puts "SDB="+JSON.dump(sdb)
puts "SYM="+JSON.dump(odb[:status][:symbol])
