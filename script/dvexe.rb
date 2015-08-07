#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new("jrafxtelch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  sl=$opt.layer_list.new(cfg)
  begin
    puts sl.get(id).exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [site] [cmd]')
  end
end
