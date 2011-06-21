#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
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
filter=ARGV.shift
al=Alias.new(id)
sdb=nil
begin
  odb=ObjDb.new(id,cls)
  cdb=ClsDb.new(cls)
  fdb=FrmDb.new(cdb['frame'])
  fobj=Frm.new(fdb,id,iocmd)
  cobj=Cls.new(cdb,id){|stm|
    fobj.request(stm)
    fobj.stat
  }
  view=View.new(cobj.stat)
  pr=Print.new
  opt.split('').each{|s|
    case s
    when 'l'
      require "liblabel"
      Label.new(odb).convert(view)
    when 'g'
      require "libgroup"
      Group.new(odb).convert(view)
    when 's'
      require "libsymdb"
      require "libsym"
      sym=SymDb.new
      sym.update(odb.symtbl)
      sdb=Sym.new(sym,odb)
    end
  }
rescue SelectID
  abort "Usage: clsshell (-lgs) [cls] [id] [iocmd]\n#{$!}"
end
inf=proc{|cmd|
  cobj.dispatch(al.alias(cmd))
}
outf=proc{|stat|
  sdb.convert(view) if sdb
  opt=='lgs' ? pr.print(view) : view
}
Shell.new(cobj,inf,outf)
