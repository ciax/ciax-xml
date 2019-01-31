#!/usr/bin/env ruby
require 'json'

def _hm(a, b)
  b ||= {}
  a.keys.each { |k| b[k] = merge(a[k], b[k]) }
end

def _am(a, b)
  b ||= []
  a.size.times { |i| b[i] = merge(a[i], b[i]) }
end

def merge(a, b)
  case a
  when Hash
    _hm(a, b)
  when Array
    _am(a, b)
  else
    b = a || b
  end
  b
end
if STDIN.tty? || !file = ARGV.shift
  abort 'Usage: json_merge [status_file] < [json_data]'
end
output = {}
begin
  if test('r', file)
    open(file) do |f|
      output = JSON.parse(f.gets(nil))
    end
  end
  str = STDIN.gets(nil) || raise
  input = JSON.parse(str)
rescue
  abort
end
output = merge(input, output)
open(file, 'w') do |f|
  f.puts(JSON.dump(output))
end
