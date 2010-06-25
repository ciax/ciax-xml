#!/usr/bin/ruby
require "libmodview"
include ModView
puts view(Marshal.load(gets(nil)))
