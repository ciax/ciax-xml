#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libsymbols"

abort "Usage: jsdb [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
odb=ObjDb.new(obj,cls)
sdb=Symbols.new(odb[:status])
puts 'OBJ="'+obj+'";'
puts "SDB="+JSON.dump(sdb)+";"
puts "SYM="+JSON.dump(sdb.ref)+";"
