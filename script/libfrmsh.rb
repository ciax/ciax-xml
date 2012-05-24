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
      reg=@field.val.keys.join('|')
      @cobj.extend(Command::Exe)
      @cobj.add_group('int',"Internal Command")
      @cobj.add_case('int','set',"Set Value [key(:idx)] (val)",reg)
      @cobj.add_case('int','unset',"Remove Value [key]",reg)
      @cobj.add_case('int','save',"Save Field [key,key...] (tag)",reg)
      @cobj.add_case('int','load',"Load Field (tag)")
      @cobj.add_case('int','sleep',"Sleep [n] sec",'[0-9]')
    end

    def to_s
      @field.to_s
    end
  end
end
