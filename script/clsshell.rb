#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
require "libobjdb"
require "libclsdb"
require "libfrmdb"
require "libalias"
require "libfilter"
require "libview"
require "libshell"
require "libprint"

def filters(opt,odb)
  filters=[]
  opt.split('').each{|s|
    case s
    when 'l'
      require "liblabel"
      filters << Label.new(odb)
    when 'g'
      require "libgroup"
      filters << Group.new(odb)
    when 's'
      require "libsymdb"
      require "libsym"
      sym=SymDb.new
      sym.update(odb.symtbl)
      filters << Sym.new(sym,odb)
    end
  }
  filters
end

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
out=Filter.new(filter)
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
  fi=filters(opt,odb)
rescue SelectID
  abort "Usage: clsshell (-lgs) [cls] [id] [iocmd]\n#{$!}"
end
inf=proc{|cmd|
  cobj.dispatch(al.alias(cmd))
}
outf=proc{|stat|
  fi.each{|f| f.convert(view)}
  opt=='lgs' ? pr.print(view) : view
}
Shell.new(cobj,inf,outf)
