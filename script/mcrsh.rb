#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrlayer'
# CIAX-XML Macro Shell
module CIAX
  OPT.parse('cemlnr')
  begin
    Mcr::Layer.new.ext_mcr.ext_shell.shell
  rescue InvalidID
    OPT.usage('[proj] [cmd] (par)')
  end
end
