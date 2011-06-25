#!/usr/bin/ruby
require "json"
require "libclsobj"
require "libfrmobj"
require "libobjdb"
require "libclsdb"
require "libfrmdb"
require "libalias"
require "libview"
require "libshell"
require "libprint"

cls=ARGV.shift
opt='lgs'
if (/^-/ === cls)
  opt=cls.delete('-')
  cls=ARGV.shift
end
id=ARGV.shift
iocmd=ARGV.shift
al=Alias.new(id)
begin
  odb=ObjDb.new(id,cls)
  cdb=ClsDb.new(cls)
  fdb=FrmDb.new(cdb['frame'])
  fobj=FrmObj.new(fdb,id,iocmd)
  cobj=ClsObj.new(cdb,id,fobj.field){|stm|
    fobj.request(stm)
  }
  view=View.new(cobj.stat)
  view.add_label(odb) if opt.include?('l')
  view.add_arrange(odb) if opt.include?('g')
  view.init_sym(odb) if opt.include?('s')
rescue SelectID
  abort "Usage: clsshell (-lgs) [cls] [id] [iocmd]\n#{$!}"
end
Shell.new(cobj.prompt){|line|
  cobj.upd
  case line
  when nil
    cobj.interrupt
  when ''
    view.upd
    opt=='lgs' ? view.prt : view
  else
    cobj.dispatch(al.alias(line.split(" ")))
  end
}
