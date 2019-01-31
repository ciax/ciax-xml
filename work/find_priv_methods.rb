#!/usr/bin/env ruby
require 'optparse'
def getline(base)
  ary = []
  while (input = ARGF.gets)
    /^ */ =~ input
    splen = $&.length
    next if splen < 1 || /^#/ =~ $'
    break if (base && (splen < base)) || /^ *(class|module)/ =~ input
    ary << [ARGF.filename, input]
    break true if base && splen <= base
  end
ensure
  puts show(ary)
end

def show(aryary)
  return [] if (exp = @opt['i']) && !aryary.any? { |_f, line| /#{exp}/ =~ line }
  if @opt['d']
    aryary.map do |f, line|
      format("%s\t%s", Regexp.last_match(1), f) if /^ *def (\w+)/ =~ line
    end.compact
  else
    aryary.map { |f, line| format("%s\t%s", f, line) }
  end
end

# -d       : pick up method name
# -i [exp] : show method which include [exp]
@opt = {}
begin
  ARGV.getopts('di:').each { |k, v| @opt[k] = v }
rescue
  abort 'Usage: find_priv_methods (-i,d) <filename>'
end
while (input = ARGF.gets)
  next if /^( *)private/ !~ input
  true while getline(Regexp.last_match(1).length)
end
