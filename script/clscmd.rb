#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"

warn "Usage: clscmd [class] [cmd] (par)" if ARGV.size < 1

cls=ARGV.shift
cmd=ARGV.dup
begin
  cdb=XmlDoc.new('cdb',cls)
  cc=ClsCmd.new(cdb)
  ENV['VER']="#{ENV['VER']}:exec"
  cc.session(cmd){}
rescue RuntimeError
  abort $!.to_s
end
