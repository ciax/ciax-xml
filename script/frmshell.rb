#!/usr/bin/ruby
require "libfrmdb"
require "libfrmobj"
require "libshell"

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
begin
  fdb=FrmDb.new(dev)
  fobj=FrmObj.new(fdb,id,iocmd)
rescue SelectID
  abort "Usage: frmshell [dev] [id] [iocmd]\n#{$!}"
end
Shell.new([dev,'>']){|line|
  case line
  when '',nil
    fobj
  else
    fobj.request(line.split(" "))
  end
}
