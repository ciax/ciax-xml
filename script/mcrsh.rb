#!/usr/bin/ruby
require "libmcrman"

module CIAX
  module Mcr
    ENV['VER']||='init/'
    GetOpts.new('rn')
    Man::Sv.new.shell
  end
end
