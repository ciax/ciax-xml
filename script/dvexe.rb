#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new("jrafxtelch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  cl=Site::Layer.new(cfg).add($opt.layer)
  begin
    puts cl.get(id).exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [site] [cmd]')
  end
end
