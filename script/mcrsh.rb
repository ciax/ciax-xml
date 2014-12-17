#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('cmlnr')
  Mcr.new.ext_shell.shell
end
