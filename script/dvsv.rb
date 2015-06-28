#!/usr/bin/ruby
require "libsitelayer"

module CIAX
  GetOpts.new('es')
  Wat::List.new.server(ARGV)
end
