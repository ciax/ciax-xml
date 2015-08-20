#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('csemr')
  Mcr.new(Config.new).ext_server.server
  sleep
end
