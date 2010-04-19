#!/usr/bin/ruby
require "libclsstat"

warn "Usage: clsstat [class] < devstat" if ARGV.size < 1

begin
  e=ClsStat.new(ARGV.shift).set_context_node('//status')
  field=Marshal.load(gets(nil))
  stat=e.clsstat(field)
rescue RuntimeError
  puts $!
  exit 1
end
print Marshal.dump(stat)
