#!/usr/bin/ruby
require 'libint'
require 'libfield'
module Frm
  class Sh < Int::Shell
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      super()
      @cobj.add_ext(fdb,:cmdframe)
      self['id']=fdb['id']
      @port=fdb['port'].to_i-1000
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

  class Cl < Sh
    def initialize(fdb,host=nil)
      super(fdb)
      @host=Msg.type?(host||fdb['host'],String)
      @field.ext_url(@host).load
      extend(Int::Client)
    end

    def to_s
      @field.load.to_s
    end
  end
end
