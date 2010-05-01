#!/usr/bin/ruby
require "libclscmd"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: clscmd [cls] [cmd]" if ARGV.size < 1

begin
  docc=XmlDoc.new('cdb',ARGV.shift)
  c=ClsCmd.new(docc).node_with_id(ARGV.shift)
  set_title("File")
  c.set_var!(load_stat(c.property['device']))
  c.clscmd {}
rescue RuntimeError
  abort $!.to_s
end
