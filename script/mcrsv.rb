#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('csemr')
  Mcr::Exe.new(Config.new).ext_server.server
  sleep
end
