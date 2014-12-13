#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new('jecafxr')
  begin
    puts ($layer.first||Wat)::List.new.exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
