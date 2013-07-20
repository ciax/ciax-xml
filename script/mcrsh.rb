#!/usr/bin/ruby
require "libmcrsh"

CIAX::GetOpts.new
al=CIAX::App::List.new
CIAX::Mcr::List.new(al).shell

