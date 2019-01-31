#!/usr/bin/env ruby
# Get Value from JSON file
require 'json'
def _ga(h, k)
  if k == '0' || k.to_i > 0
    return get(h[k.to_i], idx) if k.to_i <= h.size
    warn('Out of range')
  else
    warn('Not number')
  end
  []
end

def _gh(h, k)
  return get(h[k], idx) if h.key?(k)
  warn("No such key [#{k}]")
  h.keys
end

def get(h, idx)
  return h if idx.empty?
  k = idx.shift
  case h
  when Array
    return _ga(h, k)
  when Hash
    return _gh(h, k)
  else
    [h]
  end
end

abort 'Usage: json_getval [key:idx] json_file' if STDIN.tty? && ARGV.size < 2
key = ARGV.shift
str = gets(nil) || exit
h = JSON.parse(str)
p get(h, key.split(':'))
