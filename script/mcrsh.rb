#!/usr/bin/ruby
require "libmcrman"

module CIAX
  GetOpts.new('cmlnr')
  ll=Layer::List.new
  begin
    ll.set(Mcr::Man)
    ll.ext_shell.shell(nil)
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
