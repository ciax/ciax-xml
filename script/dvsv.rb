#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatlist'
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  Daemon.new('dvsv', 'e') do |cfg, args|
    Wat::List.new(cfg).run(args)
  end
end
