#!/usr/bin/ruby
require "libmodview"
include ModView
view(Marshal.load(gets(nil)).sort)
