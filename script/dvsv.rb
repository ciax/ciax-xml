#!/usr/bin/ruby
require "libsitelist"
require "libwatexe"
require "libappexe"
require "libfrmexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('es')
  Site::List.new.server(ARGV)
end
