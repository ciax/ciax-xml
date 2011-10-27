#!/usr/bin/ruby
require "libmcrthrd"
require 'libshell'

id=ARGV.shift
ARGV.clear
begin
  mm=McrMan.new(id)
rescue SelectID
  warn "Usage: #{$0} [mcr]"
  Msg.exit
end
Shell.new(mm.prompt){|cmd|
  mm.exec(cmd)
}
