#!/usr/bin/ruby
require 'libint'
require 'libfield'
module Frm
  class Sh < Int::Shell
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      super(Command.new.setdb(fdb,:cmdframe))
      self['id']=fdb['id']
      @port=fdb['port'].to_i-1000
      @field=Field::Var.new.ext_file(fdb).load
      idx={:type =>'str',:list => @field.val.keys}
      any={:type =>'reg',:list => ["."]}
      grp=@cobj.add_group('int',"Internal Command")
      grp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
      grp.add_item('unset',"Remove Value [key]",[idx])
      grp.add_item('save',"Save Field [key,key...] (tag)",[any])
      grp.add_item('load',"Load Field (tag)")
      grp.add_item('sleep',"Sleep [n] sec",'[0-9]')
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
      @post_exe << proc{ @field.load }
      extend(Int::Client)
    end
  end
end
