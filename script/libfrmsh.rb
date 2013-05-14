#!/usr/bin/ruby
require 'libsh'
require 'libfield'
require "libfrmrsp"
require "libfrmcmd"
require 'liblocdb'

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
    # @< cobj,output,(upd_proc*)
    # @ extdom,field*
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      self['layer']='frm'
      self['id']=fdb['site_id']
      @field=Field::Var.new.ext_file(fdb['site_id']).load
      prom=Sh::Prompt.new(self)
      super(@field,prom)
      @extdom=@cobj.add_extdom(fdb)
      @extdom.def_proc.set{|item|@field['time']=UnixTime.now}
      idx={:type =>'str',:list => @field['val'].keys}
      any={:type =>'reg',:list => ["."]}
      intgrp=@extdom['int']
      intgrp.add_item('save',"Save Field [key,key...] (tag)",[any,any])
      intgrp.add_item('load',"Load Field (tag)",[any])
      intgrp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any]).reset_proc{|item|
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

  class Sv < Exe
    # @<< cobj,(output),(upd_proc*)
    # @< extdom,field*
    # @ io
    def initialize(fdb,iocmd=[])
      super(fdb)
      @field.ext_save.load
      @field.ext_rsp(@cobj,fdb)
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        @io.ext_logging(fdb['site_id'],fdb['version'])
        # @field.ext_sqlog
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @extdom.ext_frmcmd(@field).reset_proc{|item|
        @io.snd(item.getframe,item[:cmd])
        @field.upd{@io.rcv} && @field.save
      }
      intgrp=@extdom['int']
      intgrp['set'].reset_proc{|item|
        @field.set(item.par[0],item.par[1]).save
      }
      intgrp['save'].reset_proc{|item|
        @field.savekey(item.par[0].split(','),item.par[1])
      }
      intgrp['load'].reset_proc{|item|
        @field.load(item.par[0]||'').save
      }
      ext_server(fdb['port'].to_i)
    rescue Errno::ENOENT
      warning(" --- no json file")
    end
  end

  class List < Sh::List
    def initialize
      @ldb=Loc::Db.new
      super(@ldb.list)
    end

    def newsh(id)
      sh=Frm.new(@ldb.set(id)[:frm])
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Frm::List.new.shell(ARGV.shift)
end
