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
mm.shell{|cmd|
  mm.exe(cmd)
}
