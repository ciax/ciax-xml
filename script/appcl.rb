#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libappdb"
require "libfield"
require "libiocmd"
require "libshell"
require "libprint"
require "libview"

id=ARGV.shift
host=ARGV.shift||'localhost'

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
    line='stat'
  end
  @io.snd(line)
  time,str=@io.rcv
  json,prom[0]=str.split("\n")
  pr.upd(JSON.load(json))
}
