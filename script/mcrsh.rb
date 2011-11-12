#!/usr/bin/ruby
require "libmcrman"
require 'libshell'

id=ARGV.shift
ARGV.clear
begin
  mm=McrMan.new(id)
rescue SelectID
  warn "Usage: #{$0} [mcr]"
  Msg.exit
end
Shell.new(mm.prompt,mm.commands){|cmd|
  mm.exec(cmd)
}
