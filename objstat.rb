#!/usr/bin/ruby
require "libobjstat"

warn "Usage: obstat [object] < cstat" if ARGV.size < 1
begin
  odb=ObjStat.new(ARGV.shift).set_context_node('//status')
  cstat=Marshal.load(gets(nil))
  var=odb.objstat(cstat)
rescue RuntimeError
  exit 1
end
print Marshal.dump(var)
