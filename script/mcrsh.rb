#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Macro Shell
module CIAX
  opt = GetOpts.new.parse('eclh:nr')
  begin
    Layer.new.ext_shell.shell
  rescue InvalidID
    opt.usage('[proj] [cmd] (par)')
  end
end
