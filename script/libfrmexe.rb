#!/usr/bin/ruby
require 'libint'
require 'libfield'

module Frm
  class Exe < Int::Exe
    # @< cobj,output,intcmd,(int_proc),(upd_proc*)
    # @ extcmd,field*
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      super()
      @extcmd=@cobj.add_ext(fdb,:cmdframe)
      self['id']=fdb['site']
      @output=@field=Field::Var.new.ext_file(fdb).load
      idx={:type =>'str',:list => @field.val.keys}
      any={:type =>'reg',:list => ["."]}
      grp=@intcmd.add_group('int',"Internal Command")
      grp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
      grp.add_item('unset',"Remove Value [key]",[idx])
      grp.add_item('save',"Save Field [key,key...] (tag)",[any])
      grp.add_item('load',"Load Field (tag)")
    end
  end

  class Test < Exe
    def initialize(fdb)
      super
      @cobj.def_proc.add{|item|
        @field.set_time
      }
    end
  end

  class Cl < Exe
    def initialize(fdb,host=nil)
      super(fdb)
      host=Msg.type?(host||fdb['host']||'localhost',String)
      @field.ext_url(host).load
      @cobj.def_proc.add{to_s}
      ext_client(host,fdb['port'])
      @upd_proc.add{@field.load}
    end
  end
end
