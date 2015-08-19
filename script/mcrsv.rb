#!/usr/bin/ruby
require "libmanexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('csemr')
  Mcr::Man.new(Config.new).ext_server.server
  sleep
end
