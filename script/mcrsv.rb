#!/usr/bin/ruby
require "libmcrman"

module CIAX
  module Mcr
    ENV['VER']||='init/'
    GetOpts.new('r')
    Man::Exe.new
    sleep
  end
end
