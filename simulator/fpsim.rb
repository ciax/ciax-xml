#!/usr/bin/ruby
# I/O Simulator
require 'libsimfp'
module CIAX
  module Simulator
    FpDio.new(*ARGV).start
  end
end
