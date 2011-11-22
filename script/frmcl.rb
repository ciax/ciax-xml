#!/usr/bin/ruby
require "libinsdb"
require "libfrmcl"
require "libshell"

id=ARGV.shift
host=ARGV.shift||'localhost'
begin
  fdb=InsDb.new(id).cover_app.cover_frm
rescue SelectID
  warn "Usage: frmcl [id] (host)"
  Msg.exit
end
cli=FrmCl.new(fdb,host)
Shell.new("#{id}>"){|cmd|
  cli.exe(cmd)||cli.field
}
