#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  GetOpts.new('cmlnr')
  ll=Layer::List.new
  begin
    ll.set(Mcr)
    ll.ext_shell.shell
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
