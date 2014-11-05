#!/usr/bin/ruby
require "libwatsh"

module CIAX
  module Wat
    ENV['VER']||='initialize'
    GetOpts.new('es')
    List.new.server(ARGV)
  end
end
