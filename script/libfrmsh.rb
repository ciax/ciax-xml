#!/usr/bin/ruby
require 'libsh'
require 'libfield'

module Frm
  def self.new(fdb)
    if $opt['s'] or $opt['e']
      par=$opt['s'] ? ['frmsim',fdb['site_id']] : []
      fsh=Frm::Sv.new(fdb,par)
      fsh=Frm::Cl.new(fdb,'localhost') if $opt['c']
    elsif host=$opt['h'] or $opt['c'] or $opt['f']
      fsh=Frm::Cl.new(fdb,host)
    else
      fsh=Frm::Exe.new(fdb)
    end
    fsh
  end

  class Exe < Sh::Exe
    # @< cobj,output,intgrp,(interrupt),(upd_proc*)
    # @ extdom,field*
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      self['layer']='frm'
      self['id']=fdb['site_id']
      @field=Field::Var.new.ext_file(fdb['site_id']).load
      prom=Sh::Prompt.new(self)
      super(@field,prom)
      @cobj.def_proc.set{|item|@field['time']=UnixTime.now}
      @extdom=@cobj.add_extdom(fdb,:command)
      idx={:type =>'str',:list => @field['val'].keys}
      any={:type =>'reg',:list => ["."]}
      @intgrp.add_item('save',"Save Field [key,key...] (tag)",[any,any])
      @intgrp.add_item('load',"Load Field (tag)",[any])
      @intgrp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any]).reset_proc{|item|
        @field.set(*item.par)
      }
      self
    end

    private
    def shell_conv(line)
      line='set '+line.tr('=',' ') if /^[^ ]+\=/ === line
      line
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
