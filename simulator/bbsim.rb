#!/usr/bin/ruby
require 'libsimbb'

module CIAX
  module Simulator
    sv = BBIO.new(*ARGV)
    sv.start
    sleep
  end
end
