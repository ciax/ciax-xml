#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new("jrafxtelch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  cl=Layer::List.new(cfg).add(eval "#{$opt.layer}::List")
  begin
    puts cl.get(id).exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [site] [cmd]')
  end
end
