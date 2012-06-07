#!/usr/bin/ruby
require 'libint'
require 'libfield'
module Frm
  class Sh < Int::Shell
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      super(Command.new(fdb[:cmdframe]))
      @prompt['id']=fdb['id']
      @port=fdb['port'].to_i-1000
      @field=Field::Var.new.ext_file(fdb).load
      par={:type =>'str',:list => @field.val.keys}
      grp=@cobj.add_group('int',"Internal Command")
      grp.add_item('set',"Set Value [key(:idx)] (val)",[par])
      grp.add_item('unset',"Remove Value [key]",[par])
      grp.add_item('save',"Save Field [key,key...] (tag)",[par])
      grp.add_item('load',"Load Field (tag)")
      grp.add_item('sleep',"Sleep [n] sec",'[0-9]')
    end

    def to_s
      @field.to_s
    end
  end
end
