#!/usr/bin/ruby
# Input from STDIN
# Output to base64
begin
  select([STDIN])
rescue Interrupt
  retry
end
begin
  puts [STDIN.sysread(1024)].pack("m").split("\n").join('')
rescue EOFError
  exit 1
end

