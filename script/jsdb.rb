#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libobjdb"
require "libsymdb"

obj=ARGV.shift
cls=ARGV.shift
if obj == 'all'
  puts "SDB=jQuery.extend(SDB,"+JSON.dump(SymDb.new)+");"
else
  begin
    odb=ObjDb.new(obj) >> ClsDb.new(cls)
  rescue SelectID
    abort "Usage: jsdb [obj] [class]\n#{$!}"
  end
  puts 'OBJ="'+obj+'";'
  puts "SDB="+JSON.dump(SymDb.new(cls))+";"
  puts "SYM="+JSON.dump(odb[:status][:symbol])+";"
end
