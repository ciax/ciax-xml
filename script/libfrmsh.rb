#!/usr/bin/ruby
require 'libint'
require 'libfield'
module Frm
  class Exe < Int::Exe
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      super()
      @extcmd=@cobj.add_ext(fdb,:cmdframe)
      self['id']=fdb['site']
      @field=Field::Var.new.ext_file(fdb).load
      idx={:type =>'str',:list => @field.val.keys}
      any={:type =>'reg',:list => ["."]}
      grp=@intcmd.add_group('int',"Internal Command")
      grp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
      grp.add_item('unset',"Remove Value [key]",[idx])
      grp.add_item('save',"Save Field [key,key...] (tag)",[any])
      grp.add_item('load',"Load Field (tag)")
    end

    def to_s
      @field.to_s
    end
  end

  class Cl < Exe
    def initialize(fdb,host=nil)
      super(fdb)
      @host=Msg.type?(host||fdb['host']||'localhost',String)
      @field.ext_url(@host).load
      @cobj.def_proc.add{to_s}
      ext_client(fdb['port'])
    end

    def to_s
      @field.load.to_s
    end
  end

  class List < Int::List
    def initialize
      super(){|ldb|
        if $opt['t']
          fint=Frm::Exe.new(ldb[:frm])
        elsif $opt['f']
          fint=Frm::Cl.new(ldb[:frm],$opt['h'])
        elsif $opt['i']
          Frm::Sv.new(ldb[:frm])
          fint=Frm::Cl.new(ldb[:frm],'localhost')
        else
          par=$opt['l'] ? ['frmsim',ldb[:frm]['site']] : []
          fint=Frm::Sv.new(ldb[:frm],par)
        end
        fint.ext_shell
      }
    end
  end
end
