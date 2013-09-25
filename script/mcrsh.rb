#!/usr/bin/ruby
require "libmcrman"

module CIAX
  module Mcr
    GetOpts.new('r')
    Man.new.shell
  end
end
