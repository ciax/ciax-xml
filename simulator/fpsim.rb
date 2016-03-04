#!/usr/bin/ruby
# I/O Simulator
require 'libsimfp'
module CIAX
  module Simulator
    sv = FpDio.new(*ARGV)
    sv.start
    sleep
  end
end
