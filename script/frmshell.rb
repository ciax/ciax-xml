#!/usr/bin/ruby
require "libiostat"
require "libiocmd"
require "libfrmdb"
require "libfrmobj"
require "libshell"

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
begin
  fdb=FrmDb.new(dev)
  field=IoStat.new(id,'field')
  io=IoCmd.new(iocmd,id,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
rescue SelectID
  abort "Usage: frmshell [dev] [id] [iocmd]\n#{$!}"
end
Shell.new([dev,'>']){|line|
  case line
  when '',nil
    field
  else
    fobj.request(line.split(" "))
  end
}
