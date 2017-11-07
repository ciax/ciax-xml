#!/usr/bin/ruby
# alias fpm
ind = 0
ARGF.each do |line|
  line =~ /^ */
  len = $&.length
  next if len < 1
  if line =~ /^ *private/
    ind = len
  elsif ind > 1 && ind <= len
    if line =~ /^ *def/
      $' =~ /\w+/
      puts format("%s\t%s", $&, ARGF.filename)
    end
  else
    ind = 0
  end
end
