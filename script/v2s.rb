#!/usr/bin/ruby
require "json"
require "libview"

usage="Usage: vs < json_file"

view=View.new(JSON.load(gets(nil)))
puts view
