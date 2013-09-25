#!/usr/bin/ruby
require "libmcrman"

module CIAX
  module Mcr
    GetOpts.new('r')
    Man.new.ext_server(55555)
    sleep
  end
end
