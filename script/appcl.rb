#!/usr/bin/ruby
require "liburiview"
require "libinsdb"
require "libiocmd"
require "libprint"
require "libparam"
require "libshell"

id=ARGV.shift
host=ARGV.shift||'localhost'
view=UriView.new(id,host)
begin
  idb=InsDb.new(id).cover_app
  @io=IoCmd.new(["socat","-","udp:#{host}:#{idb['port']}"])
rescue SelectID
  warn "Usage: appcl [id] (host)"
  Msg.exit
end
pr=Print.new(idb[:status],view)
par=Param.new(idb[:command])
prom=['']
Shell.new(prom){|line|
  break unless line
  @io.snd(line.empty? ? 'stat' : line)
  time,str=@io.rcv
  ary=str.split("\n")
  prom[0]=ary.pop
  case ary.first
  when nil
    view.upd
    pr.upd
  when /CMD/
    par.list
  else
    ary.first
  end
}
