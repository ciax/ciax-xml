#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Macro Shell
module CIAX
  ARGV.unshift '-m'
  Layer.new('meclh:nr').ext_shell.shell
end
