#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrman'
# CIAX-XML Macro Server
module CIAX
  OPT.parse('csemr')
  Mcr::Man::Exe.new(Config.new).ext_server.server
  sleep
end
