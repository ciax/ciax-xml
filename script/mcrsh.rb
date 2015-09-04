#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('cemlnr')
  begin
    Layer::List.new(:top_layer => Mcr).ext_shell.shell
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
