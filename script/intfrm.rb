#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintfrms"

opt=ARGV.getopts("cs")
id,*cobj=ARGV
begin
  fint=IntFrms.new.add(id,opt,cobj)[id]
rescue UserError
  Msg.usage("(-cs) [id] (host|iocmd)","-s:server, -c:client")
end
sleep if opt["s"]
require 'libshell'
Shell.new(fint.prompt,fint.commands){|line|
  fint.exe(line)||fint
}
