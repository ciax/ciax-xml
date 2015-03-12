#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new("jrafxtelch:")
  db={'x' => Hex,'f'=> Frm,'a'=> App,'w'=> Wat}
  layer=$opt.map{|k,v| db[k] if v}.compact.last||Wat
  begin
    puts layer::List.new.exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [site] [cmd]')
  end
end
