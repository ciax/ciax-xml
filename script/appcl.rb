#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libappdb"
require "libfield"
require "libiocmd"
require "libshell"
require "libprint"
require "libview"
require "open-uri"

id=ARGV.shift
host=ARGV.shift||'localhost'
url="http://#{host}/json/status_#{id}.json"
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
  case line
  when nil
    break
  when ''
    open(url){|f|
      pr.upd(JSON.load(f.read))
    }
    pr
  else
    @io.snd(line)
    time,str=@io.rcv
    ary=str.split("\n")
    prom[0]=ary.pop
    ary
  end
}
