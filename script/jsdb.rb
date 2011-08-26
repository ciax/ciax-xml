#!/usr/bin/ruby
require "json"
require "libappdb"
require "libobjdb"
require "libsymdb"

obj=ARGV.shift
cls=ARGV.shift
if obj == 'all'
  puts "SDB=jQuery.extend(SDB,"+JSON.dump(SymDb.new)+");"
else
  begin
    odb=ObjDb.new(obj) >> AppDb.new(cls)
  rescue SelectID
    abort "Usage: jsdb [obj] [app]\n#{$!}"
  end
  puts 'OBJ="'+obj+'";'
  puts "SDB="+JSON.dump(SymDb.new(cls))+";"
  puts "SYM="+JSON.dump(odb[:status][:symbol])+";"
end
