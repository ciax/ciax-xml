#!/usr/bin/ruby
h=Marshal.load(gets(nil))
ENV['mar'].split(',').each {|str|
  k,v=str.split(':')
  h[k]=v
}
print Marshal.dump(h)
