#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libobjdb"
require "libsymdb"

abort "Usage: jsdb [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
odb=ClsDb.new(cls) << ObjDb.new(obj)
sdb=SymDb.new(cls)
puts 'OBJ="'+obj+'";'
puts "SDB="+JSON.dump(sdb)+";"
puts "SYM="+JSON.dump(odb[:status][:symbol])+";"
