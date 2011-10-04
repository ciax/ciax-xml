#!/usr/bin/ruby
require "libclient"
require "libinsdb"
require "libprint"
require "libshell"

id=ARGV.shift
host=ARGV.shift||'localhost'
begin
  idb=InsDb.new(id)
  cli=Client.new(idb,host)
rescue SelectID
  warn "Usage: appcl [id] (host)"
  Msg.exit
end
pr=Print.new(idb[:status],cli.view)
Shell.new(cli.prompt){|line|
  break unless line
  cli.upd(line) || pr
}
