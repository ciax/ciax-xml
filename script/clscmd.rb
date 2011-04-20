#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"

usage="Usage: clscmd [class] [cmd] (par)\n"
cls=ARGV.shift
cmd=ARGV
begin
  doc=XmlDoc.new('cdb',cls,usage)
  cc=ClsCmd.new(doc)
  cc.setcmd(cmd).statements.each{|c| p c}
rescue ParameterError
  abort $!.to_s
end
