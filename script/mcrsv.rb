#!/usr/bin/ruby
require 'libmcrman'
# CIAX-XML Macro Server
module CIAX
  ENV['VER'] ||= 'initialize'
  OPT.parse('csemr')
  Mcr::Exe.new(Config.new).ext_server.server
  sleep
end
