#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('mlnr')
  Mcr.new.ext_shell.shell
end
