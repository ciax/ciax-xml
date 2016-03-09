#!/usr/bin/ruby
require 'libsimarm'

module CIAX
  module Simulator
    sv = Arm.new
    sv.start
    sleep
  end
end
