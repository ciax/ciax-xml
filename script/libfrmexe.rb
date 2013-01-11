#!/usr/bin/ruby
require 'libint'
require 'libfield'

module Frm
  class Exe < Int::Exe
    # @< cobj,output,intgrp,(interrupt),(int_proc),(upd_proc*)
    # @ extdom,field*
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      super()
      @extdom=@cobj.add_extdom(fdb,:cmdframe)
      self['id']=fdb['site_id']
      @output=@field=Field::Var.new.ext_file(fdb['site_id']).load
      idx={:type =>'str',:list => @field['val'].keys}
      any={:type =>'reg',:list => ["."]}
      @intgrp.add_item('save',"Save Field [key,key...] (tag)",[any])
      @intgrp.add_item('load',"Load Field (tag)")
      @intgrp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
    end
  end

  class Test < Exe
    def initialize(fdb)
      super
      @cobj.def_proc.set{|item|
        @field.set_time
      }
      @cobj['set'].init_proc{|item|
        @field.set(*item.par)
      }
    end
  end

  class Cl < Exe
    def initialize(fdb,host=nil)
      super(fdb)
      host=Msg.type?(host||fdb['host']||'localhost',String)
      @field.ext_url(host).load
      @cobj.def_proc.set{to_s}
      client(host,fdb['port'])
      @upd_proc.add{@field.load}
    end
  end
end
