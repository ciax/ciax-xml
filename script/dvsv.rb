#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER'] ||= 'Initialize'
require 'libwatlist'
# CIAX-XML Device Server
module CIAX
  OPT.parse('es')
  cfg = Config.new
  Threadx.reload('dvsv') do |args|
    #  Msg.err2file('dvsv')
    Wat::List.new(cfg).server(ARGV+args)
  end
end
