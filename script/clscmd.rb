#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"

warn "Usage: clscmd [class] [cmd] (par)" if ARGV.size < 1

cls=ARGV.shift
cmd=ARGV
begin
  cdb=XmlDoc.new('cdb',cls)
  cc=ClsCmd.new(cdb)
  cc.session(cmd){|c| p c}
rescue SelectID
  abort $!.to_s
end
