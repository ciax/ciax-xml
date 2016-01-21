#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER'] ||= 'Initialize'
require 'libmcrman'
# CIAX-XML Macro Server
module CIAX
  OPT.parse('csenr')
  cfg = Config.new
  begin
    cfg[:dev_list] = Wat::List.new(cfg)
    Mcr::Man.new(cfg).ext_server.server
    sleep
  rescue InvalidID
    OPT.usage('[proj] [cmd] (par)')
  end
end
