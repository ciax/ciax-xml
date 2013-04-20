#!/usr/bin/ruby
require 'libinteractive'
require 'libfield'

module Frm
  class Exe < Interactive::Exe
    # @< cobj,output,intgrp,(interrupt),(upd_proc*)
    # @ extdom,field*
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      self['id']=fdb['site_id']
      @field=Field::Var.new.ext_file(fdb['site_id']).load
      super(@field)
      @extdom=@cobj.add_extdom(fdb,:cmdframe)
      idx={:type =>'str',:list => @field['val'].keys}
      any={:type =>'reg',:list => ["."]}
      @intgrp.add_item('save',"Save Field [key,key...] (tag)",[any])
      @intgrp.add_item('load',"Load Field (tag)")
      @intgrp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any])
      self
    end

    private
    def lineconv(line)
      line='set '+line.tr('=',' ') if /^[^ ]+\=/ === line
      line
    end
  end

  class Test < Exe
    def initialize(fdb)
      super
      @cobj.def_proc.set{|item|
        @field['time']=UnixTime.now
      }
      @cobj['set'].reset_proc{|item|
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
      ext_client(host,fdb['port'])
      @upd_proc.add{@field.load}
    end
  end
end
