#!/usr/bin/ruby
require "libmcrman"

module CIAX
  module Mcr
    ENV['VER']||='init/'
    GetOpts.new('r')
    Sv.new
    sleep
  end
end
