#!/usr/bin/ruby
require "libiostat"
require "libiocmd"
require "libfrmdb"
require "libfrmobj"
require "libinteract"

dev,id,iocmd,port=ARGV
begin
  fdb=FrmDb.new(dev)
  field=IoStat.new(id,'field')
  io=IoCmd.new(iocmd,id,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
rescue SelectID
  abort "Usage: frmshell [dev] [id] [iocmd] (port)\n#{$!}"
end
Interact.new(port||[dev,'>']){|line|
  (line && fobj.request(line.split(' ')))||\
  (port ? field.to_j : field)
}
