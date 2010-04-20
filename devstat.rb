#!/usr/bin/ruby
require "libdevstat"
require "libxmldoc"

warn "Usage: devstat [dev] [cmd] < file" if ARGV.size < 1

begin
  doc=XmlDoc.new('ddb',ARGV.shift)
  e=DevStat.new(doc)
  e.node_with_id!(ARGV.shift)
rescue
  puts $!
  exit 1
end
print Marshal.dump e.devstat(gets(nil))
