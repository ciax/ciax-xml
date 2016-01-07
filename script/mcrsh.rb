#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Macro Shell
module CIAX
  OPT.parse('cemlnr')
  begin
    Layer.new.ext_shell.shell
  rescue InvalidID
    OPT.usage('[proj] [cmd] (par)')
  end
end
