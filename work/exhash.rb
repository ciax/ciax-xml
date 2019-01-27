#!/usr/bin/ruby
require 'libhashx'
# CIAX-XML
module CIAX
  w = Hashx.new
  w[:a] = 1
  w[:c] = []
  w[:e] = { x: 1 }
  print 'w='
  p w
  r = Hashx.new
  r[:b] = 2
  r[:d] = {}
  r[:f] = [1]
  print 'r='
  p r
  w.deep_update r
  puts 'w <- r(over write)'
  p w
  puts
  r = Hashx.new
  r[:c] = { m: 'm' }
  r[:d] = [1]
  print 'r='
  p r
  w = Hashx.new
  w[:c] = { i: 'i' }
  w[:d] = [2, 3]
  print 'w='
  p w
  w.deep_update r
  puts 'w <- r(over write)'
  p w
  puts
  r = Hashx.new
  r[:c] = { m: 'm', n: { x: 'x' } }
  r[:d] = [1]
  r[:e] = 'e'
  print 'r='
  p r
  w = Hashx.new
  w[:c] = { i: 'i', n: { y: 'y' } }
  w[:d] = [2, 3]
  w[:f] = 'f'
  print 'w='
  p w
  w.deep_update r
  puts 'w <- r(over write)'
  p w
end
