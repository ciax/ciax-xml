#!/usr/bin/ruby
require "libmcrsh"

CIAX::GetOpts.new
il=CIAX::Ins::Layer.new
CIAX::Mcr::List.new(il).shell

