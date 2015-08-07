#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new("jrafxtelch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  ll=Layer::List.new(cfg)
  ll.set(eval "#{$opt.layer}::List.new(cfg)")
  begin
    puts ll.get(id).exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [site] [cmd]')
  end
end
