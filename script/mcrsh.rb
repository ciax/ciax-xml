#!/usr/bin/ruby
require "libmcrman"
CIAX::GetOpts.new
begin
  il=CIAX::Ins::Layer.new
  man=CIAX::Mcr::List.new(il)
  man.shell
rescue CIAX::InvalidCMD
  $opt.usage
end

