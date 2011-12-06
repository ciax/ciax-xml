#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintfrms"

opt=ARGV.getopts("cds")
id,host=ARGV
begin
  fint=IntFrms.new.add(id,opt,host)[id]
rescue UserError
  Msg.usage("(-csd) [id] (host)","-s:server, -c:client, -d:dummy")
end
sleep if opt["s"]
require 'libshell'
Shell.new(fint.prompt,fint.commands){|line|
  fint.exe(line)||fint
}
