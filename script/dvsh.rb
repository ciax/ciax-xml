#!/usr/bin/ruby
require "libsitelayer"
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("aelsch:")
  Site::Layer.new(:site => ARGV.shift,:layer => 'app').ext_shell.shell
end
