#!/usr/bin/ruby
require "json"
require "libappdb"
require "libobjdb"
require "libsymdb"

obj=ARGV.shift
app=ARGV.shift
if obj == 'all'
  puts "SDB=jQuery.extend(SDB,"+JSON.dump(SymDb.new)+");"
else
  begin
    odb=ObjDb.new(obj) >> AppDb.new(app)
  rescue SelectID
    abort "Usage: jsdb [obj] [app]\n#{$!}"
  end
  puts 'OBJ="'+obj+'";'
  puts "SDB="+JSON.dump(SymDb.new(app))+";"
  puts "SYM="+JSON.dump(odb[:status][:symbol])+";"
end
