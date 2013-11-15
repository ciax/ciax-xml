#!/usr/bin/ruby
require "libhexsh"

module CIAX
  module App
    ENV['VER']||='init/'
    GetOpts.new('es')
    List.new.server(ARGV)
  end
end
