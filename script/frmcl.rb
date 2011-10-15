#!/usr/bin/ruby
require "libinsdb"
require "libclient"
require "libiofile"
require "libparam"
require "libshell"

id=ARGV.shift
host=ARGV.shift||'localhost'
begin
  fdb=InsDb.new(id).cover_app.cover_frm
rescue SelectID
  warn "Usage: frmcl [id] (host)"
  Msg.exit
end
cli=Client.new(id,fdb['port'].to_i-1000,host)
field=IoFile.new('field',id,host)
par=Param.new(fdb[:cmdframe])
Shell.new(cli.prompt){|cmd|
  case msg=cli.upd(cmd).message
  when nil
    field.load
  when /CMD/
    par.set(cmd)
  else
    msg
  end
}
