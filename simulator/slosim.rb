#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  module Simulator
    sv = Slosyn.new(*ARGV)
    sv.start
    sleep
  end
end
