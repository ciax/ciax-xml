#!/usr/bin/ruby
require "libhexexe"

module CIAX
  layer=GetOpts.new('jecafxr').layer||Wat
  begin
    puts layer::List.new.exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
