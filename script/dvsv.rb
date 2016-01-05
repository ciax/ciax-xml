#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER'] ||= 'Initialize'
require 'libwatlist'
# CIAX-XML Device Server
module CIAX
  OPT.parse('es')
  cfg = Config.new
  $stderr.reopen(Msg.vardir('log') + "error_dvsv.out","a")
  Wat::List.new(cfg).server(ARGV)
end
