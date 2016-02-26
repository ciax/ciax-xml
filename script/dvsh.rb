#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libsitelayer'
# CIAX-XML Device Shell
module CIAX
  Site::Layer.new('fawxelrch:').ext_shell.shell
end
