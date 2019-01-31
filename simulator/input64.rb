#!/usr/bin/env ruby
# Input from STDIN
# Output to base64
begin
  puts [STDIN.readpartial(1024)].pack('m').split("\n").join('')
rescue EOFError
  exit 1
end
