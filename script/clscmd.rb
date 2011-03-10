#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"

warn "Usage: clscmd [class] [cmd] (par)" if ARGV.size < 1

cls=ARGV.shift
cmd=ARGV
begin
  doc=XmlDoc.new('cdb',cls)
  cc=ClsCmd.new(doc)
  cc.setcmd(cmd).session.each{|c| p c}
rescue RuntimeError
  abort $!.to_s
end
