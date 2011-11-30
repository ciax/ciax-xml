#!/usr/bin/ruby
require "libmcrman"
require 'libshell'

id=ARGV.shift
ARGV.clear
begin
  mm=McrMan.new(id)
rescue SelectID
  Msg.usage("[mcr] # (ACT=n)")
end
Shell.new(mm.prompt,mm.commands){|cmd|
  mm.upd(cmd)
}
