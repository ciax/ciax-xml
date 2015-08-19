#!/usr/bin/ruby
require "libmanexe"

module CIAX
  GetOpts.new('cmlnr')
  ll=Layer::List.new
  begin
    ll.set(Mcr::Man)
    ll.ext_shell.shell
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
