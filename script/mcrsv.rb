#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrman'
# CIAX-XML Macro Server
module CIAX
  OPT.parse('csenmr')
  cfg=Config.new
  cfg[:dev_list]=Wat::List.new(cfg)
  Mcr::Man::Exe.new(cfg).ext_server.server
  sleep
end
