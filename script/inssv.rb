#!/usr/bin/ruby
require "libwatsh"

module CIAX
  module Watch
    ENV['VER']||='init/'
    GetOpts.new('es')
    List.new.server(ARGV)
  end
end
