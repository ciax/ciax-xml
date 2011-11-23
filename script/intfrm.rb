#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintfrms"

opt=ARGV.getopts("cs")
id,*par=ARGV
begin
  fint=IntFrms.new.add(id,opt,par)[id]
rescue UserError
  warn "Usage: intfrm (-cs) [id] (host|iocmd) # -c:client, -s:server"
  Msg.exit
end
sleep if opt["s"]
require 'libshell'
Shell.new(fint.prompt,fint.commands){|line|
  fint.exe(line)||fint
}
