#!/usr/bin/ruby
require "libmcrsh"

module CIAX
  module Mcr
    GetOpts.new('r')
    List.new.shell('0')
  end
end
