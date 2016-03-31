#!/usr/bin/ruby
require 'libsimbb'

module CIAX
  module Simulator
    BBIO.new(*ARGV).start
  end
end
