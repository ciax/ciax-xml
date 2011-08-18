#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libobjdb"
require "libsymbols"

abort "Usage: jsdb [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
cdb=ClsDb.new(cls)
odb=ObjDb.new(obj).cover(cdb)
sdb=Symbols.new(odb[:status])
puts 'OBJ="'+obj+'";'
puts "SDB="+JSON.dump(sdb)+";"
puts "SYM="+JSON.dump(sdb.ref)+";"
