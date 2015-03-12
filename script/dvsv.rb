#!/usr/bin/ruby
require "libwatlist"

module CIAX
  GetOpts.new('es')
  Wat::List.new.server(ARGV)
end
