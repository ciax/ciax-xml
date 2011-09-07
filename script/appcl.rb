#!/usr/bin/ruby
require "libobjdb"
require "libappdb"
require "libfield"
require "libiocmd"
require "libshell"
require "libprint"
require "libview"
require "liburlstat"

id=ARGV.shift
host=ARGV.shift||'localhost'
st=UrlStat.new(id,host)
begin
  odb=ObjDb.new(id)
  odb >> AppDb.new(odb['app_type'])
  @io=IoCmd.new("socat - udp:#{host}:#{odb['port']}")
rescue SelectID
  abort "Usage: appcl [id] (host)\n#{$!}"
end
pr=Print.new(odb[:status])
prom=['>']
Shell.new(prom){|line|
  break unless line
  @io.snd(line.empty? ? 'stat' : line)
  time,str=@io.rcv
  ary=str.split("\n")
  prom[0]=ary.pop
  ary.empty? ? pr.upd(st.get) : ary
}
