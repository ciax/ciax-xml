#!/usr/bin/env ruby
# Set value to JSON file
require 'json'

def chk_num(k)
  if k == '0' || k.to_i > 0
    return true if k.to_i <= h.size
    warn("Out of range [0..#{h.size - 1}]")
  else
    warn("Not number [#{k}]")
  end
  false
end

def setary(h, k, v)
  return unless chk_num(k)
  if h[k.to_i].is_a? Enumerable
    h[k.to_i]
  else
    h[k.to_i] = v
  end
end

def sethash(h, k, v)
  if h.key?(k)
    if h[k].is_a? Enumerable
      h[k]
    else
      h[k] = v
    end
  else
    warn("No such key [#{k}]")
    h.keys
  end
end

def setval(h, k, v)
  case h
  when Array
    setary(h, k, v)
  when Hash
    sethash(h, k, v)
  else
    h
  end
end

abort 'Usage: json_setval [key(:idx)=n] .. < json_file' if STDIN.tty?
exp = [].concat(ARGV)
ARGV.clear

field = JSON.parse(gets(nil))
exp.each do |e|
  key, v = e.split('=').map(&:strip)
  final = key.split(':').inject(field) { |h, k| setval(h, k, v) }
  abort("Key shortage\n  #{final}") if final.is_a? Enumerable
end
jj field
