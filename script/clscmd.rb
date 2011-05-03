#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"

usage="Usage: clscmd [class] [cmd] (par)"
cls=ARGV.shift
cmd=ARGV
begin
  doc=XmlDoc.new('cdb',cls,usage)
  cc=ClsCmd.new(doc)
  cc.setcmd(cmd).statements.each{|c| p c}
rescue UserError
  abort $!.to_s
end
