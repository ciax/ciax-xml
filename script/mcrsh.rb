#!/usr/bin/ruby
require "libmcrman"
require 'libshell'

id=ARGV.shift
ARGV.clear
begin
  mm=McrMan.new(id)
rescue SelectID
  warn "Usage:(ACT=1)  #{$0.split('/').last} [mcr]"
  Msg.exit
end
Shell.new(mm.prompt,mm.commands){|cmd|
  mm.exec(cmd)
}
