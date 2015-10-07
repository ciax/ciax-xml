#!/usr/bin/ruby
require 'json'

def merge(a, b)
  case a
  when Hash
    b ||= {}
    a.keys.each do|k|
      b[k] = merge(a[k], b[k])
    end
  when Array
    b ||= []
    a.size.times do|i|
      b[i] = merge(a[i], b[i])
    end
  else
    b = a || b
  end
  b
end
if STDIN.tty? || !file = ARGV.shift
  abort "Usage: json_merge [status_file] < [json_data]\n#{$ERROR_INFO}"
end
output = {}
begin
  open(file) do|f|
    output = JSON.load(f.gets(nil))
  end if test('r', file)
  str = STDIN.gets(nil) || fail
  input = JSON.load(str)
rescue
  abort
end
output = merge(input, output)
open(file, 'w') do|f|
  f.puts(JSON.dump(output))
end
