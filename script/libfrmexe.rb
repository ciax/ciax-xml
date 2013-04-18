#!/usr/bin/ruby
require 'libinteractive'
require 'libfield'

module Frm
  module Exe
    # @< cobj,output,intgrp,(interrupt),(upd_proc*)
    # @ extdom,field*
    attr_reader :field
    def init(fdb)
      Msg.type?(fdb,Frm::Db)
      @extdom=@cobj.add_extdom(fdb,:cmdframe)
      self['id']=fdb['site_id']
      @output=@field=Field::Var.new.ext_file(fdb['site_id']).load
      idx={:type =>'str',:list => @field['val'].keys}
      any={:type =>'reg',:list => ["."]}
      @intgrp.add_item('save',"Save Field [key,key...] (tag)",[any])
      @intgrp.add_item('load',"Load Field (tag)")
      @intgrp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
      self
    end
  end

  class Test < Interactive::Exe
    def initialize(fdb)
      super()
      extend(Exe).init(fdb)
      @cobj.def_proc.set{|item|
        @field['time']=Sec.now
      }
      @cobj['set'].reset_proc{|item|
        @field.set(*item.par)
      }
    end
  end

  class Cl < Interactive::Client
    def initialize(fdb,host=nil)
      super()
      extend(Exe).init(fdb)
      host=Msg.type?(host||fdb['host']||'localhost',String)
      @field.ext_url(host).load
      @cobj.def_proc.set{to_s}
      client(host,fdb['port'])
      @upd_proc.add{@field.load}
    end
  end
end
