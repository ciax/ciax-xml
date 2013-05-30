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
    elsif host=$opt['h'] or $opt['c']
      fsh=Frm::Cl.new(fdb,host)
    else
      fsh=Frm::Exe.new(fdb)
    end
    fsh
  end

  class Exe < Sh::Exe
    # @< cobj,output,(upd_proc*)
    # @ svdom,extgrp,intgrp,field*
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      self['layer']='frm'
      self['id']=fdb['site_id']
      @field=Field::Var.new.ext_file(fdb['site_id']).load
      prom=Sh::Prompt.new(self)
      super(@field,prom)
      @cobj['sv'].def_proc=proc{|item|@field['time']=UnixTime.now}
      any={:type =>'reg',:list => ["."]}
      @intgrp=@cobj['sv']['int']
      @intgrp.add_item('save',"Save Field [key,key...] (tag)",[any,any])
      @intgrp.add_item('load',"Load Field (tag)",[any])
      @intgrp.add_item('set',"Set Value [key(:idx)] [val(,val)]",[any,any]).def_proc=proc{|item|
        @field.set(*item.par)
      }
      @extgrp=@cobj['sv']['ext']=ExtGrp.new(fdb,@field)
      self
    end

    private
    def shell_input(line)
      cmd=line.split(/[ =]/)
      cmd.unshift 'set' if /^[^ ]+\=/ === line
      cmd
    end
  end

  class Cl < Exe
    def initialize(fdb,host=nil)
      super(fdb)
      host=Msg.type?(host||fdb['host']||'localhost',String)
      @field.ext_url(host).load
      @cobj['sv'].def_proc=proc{to_s}
      ext_client(host,fdb['port'])
      @upd_proc.add{@field.load}
    end
  end

  class Sv < Exe
    # @<< cobj,(output),(upd_proc*)
    # @< svdom,field*
    # @ io
    def initialize(fdb,iocmd=[])
      super(fdb)
      @field.ext_save.load
      @field.ext_rsp(fdb)
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        @io.ext_logging(fdb['site_id'],fdb['version'])
        # @field.ext_sqlog
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @extgrp.def_proc=proc{|item|
        @io.snd(item.getframe,item[:cmd])
        @field.upd(item){@io.rcv} && @field.save
      }
      @intgrp['set'].def_proc=proc{|item|
        @field.set(item.par[0],item.par[1]).save
      }
      @intgrp['save'].def_proc=proc{|item|
        @field.savekey(item.par[0].split(','),item.par[1])
      }
      @intgrp['load'].def_proc=proc{|item|
        @field.load(item.par[0]||'').save
      }
      ext_server(fdb['port'].to_i)
    rescue Errno::ENOENT
      warning(" --- no json file")
    end
  end

  class List < Sh::DevList
    def initialize(current=nil)
      @ldb=Loc::Db.new
      super(@ldb.list,"#{current}")
    end

    def newsh(id)
      Frm.new(@ldb.set(id)[:frm])
    end
  end
end

if __FILE__ == $0
  ENV['VER']||='init/'
  Msg::GetOpts.new('cet')
  begin
    puts Frm::List.new(ARGV.shift).shell
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
