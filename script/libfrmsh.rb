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

  class Sh < Exe
    def initialize(fdb)
      super
      ext_shell
    end
  end

  class Cl < Sh
    def initialize(fdb,host=nil)
      super(fdb)
      @host=Msg.type?(host||fdb['host']||'localhost',String)
      @field.ext_url(@host).load
      @cobj.def_proc << proc{to_s}
      ext_client(fdb['port'])
    end

    def to_s
      @field.load.to_s
    end
  end

  class List < Int::List
    def initialize
      super(){|ldb|
        yield ldb[:frm]
      }
    end

    def shell(id)
      true while id=self[id].shell
    rescue UserError
      Msg.usage('(opt) [id] ....',*$optlist)
    end
  end
end
