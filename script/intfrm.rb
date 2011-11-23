#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintfrms"

opt=ARGV.getopts("sf")
id,*par=ARGV
begin
  fint=IntFrms.new.add(id,opt,par)[id]
rescue UserError
  warn "Usage: intfrm (-sf) [id] (host|iocmd)"
  Msg.exit
end

if opt["s"]
  require 'libserver'
  Server.new(fint.port,fint.prompt){|line|
    fint.exe(line)
  }
else
  require 'libshell'
  Shell.new(fint.prompt,fint.commands){|line|
    fint.exe(line)||fint
  }
end
