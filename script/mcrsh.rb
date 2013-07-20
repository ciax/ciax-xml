#!/usr/bin/ruby
require "libmcrsh"

module CIAX
  GetOpts.new
  il=Ins::Layer.new
  il.add('mcr',il['app'],Mcr::List)
  il.shell
end
