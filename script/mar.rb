#!/usr/bin/ruby
Marshal.load(gets(nil)).sort.each { |e| p e }
