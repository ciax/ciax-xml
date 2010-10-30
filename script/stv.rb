#!/usr/bin/ruby
require "json"
require "libmodview"
include ModView
puts view(JSON.load(gets(nil)))
