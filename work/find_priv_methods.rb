#!/usr/bin/ruby
#alias fpm
def getline
  while (line = ARGF.gets)
    line =~ /^ */
    splen = $&.length
    next if splen < 1 || $' =~ /^#/
    yield line, splen
  end
end

getline do |line1, base|
  next if line1 !~ /^ *private/
  getline do |line2, ind|
    break if base > ind || line2 =~ /^ *(class|module)/
    next if line2 !~ /^ *def/
    ($' =~ /\w+/)
    puts format("%s\t%s", $&, ARGF.filename)
  end
end
