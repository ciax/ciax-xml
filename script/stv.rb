#!/usr/bin/ruby
require "libmodview"
include ModView
print view(Marshal.load(gets(nil)))
