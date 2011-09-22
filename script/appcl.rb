#!/usr/bin/ruby
require "libentdb"
require "libfield"
require "libiocmd"
require "libshell"
require "libprint"
require "libparam"
require "libview"
require "liburiview"

id=ARGV.shift
host=ARGV.shift||'localhost'
view=UriView.new(id,host)
begin
  edb=EntDb.new(id).cover_app
  @io=IoCmd.new("socat - udp:#{host}:#{edb['port']}")
rescue SelectID
  abort "Usage: appcl [id] (host)\n#{$!}"
end
pr=Print.new(edb[:status],view)
par=Param.new(edb[:command],:structure)
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
