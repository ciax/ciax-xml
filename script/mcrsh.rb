#!/usr/bin/ruby
require "libmcrman"

module CIAX
  GetOpts.new('cmlnr')
  cfg=Config.new
  cfg[:jump_groups]=[]
  ll=Layer::List.new(cfg)
  begin
    ll.set(Mcr::Man.new(cfg))
    ll.ext_shell.shell(nil)
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
