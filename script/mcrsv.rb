#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER'] ||= 'Initialize'
require 'libmcrman'
# CIAX-XML Macro Server
module CIAX
  OPT.parse('csenr')
  cfg = Config.new
  Msg.daemon('mcrsv') do
    Mcr::Man.new(cfg).ext_server
  end
end
