#!/usr/bin/ruby
require "libmcrdb"
require "libmcrobj"
require 'libshell'

id=ARGV.shift
ARGV.clear
begin
  ac=McrObj.new
  mdb=McrDb.new(id)
  par=Param.new(mdb)
rescue SelectID
  warn "Usage: #{$0} [mcr]"
  Msg.exit
end
Shell.new(ac.prompt){|cmd|
  if /Y|y/ === cmd[0]
    ac.proceed
  elsif cmd.empty?
  else
    par.set(cmd)
    ac.mcr(par)
  end
  ac
}
