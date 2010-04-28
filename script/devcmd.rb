#!/usr/bin/ruby
require "libdevcmd"
require "libxmldoc"

warn "Usage: devcmd [dev] [cmd] (par)" if ARGV.size < 1

begin
  doc=XmlDoc.new('ddb',ARGV.shift)
  e=DevCmd.new(doc)
  e.node_with_id!(ARGV.shift)
rescue
  abort $!.to_s
end
begin
  e.devcmd(ARGV.shift) do |cmd|
    puts cmd
  end
rescue IndexError
  abort $!.to_s
end





