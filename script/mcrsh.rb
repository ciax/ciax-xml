#!/usr/bin/ruby
require "libmcrsh"

module CIAX
  GetOpts.new('r')
  il=Ins::Layer.new
  il.add('mcr',Mcr::Man.new(il['app']))
  il.shell('0')
end
