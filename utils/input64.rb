#!/usr/bin/ruby
# Input from STDIN
# Output to base64
begin
  select([STDIN])
  puts [STDIN.sysread(1024)].pack("m").split("\n").join('')
rescue EOFError
end

