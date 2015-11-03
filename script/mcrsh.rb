#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrlayer'
# CIAX-XML Macro Shell
module CIAX
  OPT.parse('cemlnr')
  PROJ ||= ARGV.shift
  begin
    Mcr::Layer.new.ext_shell.shell
  rescue InvalidID
    OPT.usage('[proj] [cmd] (par)')
  end
end
