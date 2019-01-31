#!/usr/bin/env ruby
require 'ox'
require 'json'
jj Ox.load(IO.read(ARGV.shift), mode: :hash)
