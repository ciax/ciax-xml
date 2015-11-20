#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER']||='Initialize'
require 'libmcrman'
# CIAX-XML Macro Server
module CIAX
  OPT.parse('csenmr')
  cfg = Config.new
  begin
    cfg[:dev_list] = Wat::List.new(cfg).sub_list
    Mcr::Man.new(cfg).ext_server.server
    sleep
  rescue InvalidID
    OPT.usage('[proj] [cmd] (par)')
  end
end
