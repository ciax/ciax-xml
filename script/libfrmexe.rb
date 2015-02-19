#!/usr/bin/ruby
require "libexe"
require "libfield"
require "libfrmdb"
require "libfrmrsp"
require "libfrmcmd"

module CIAX
  $layers['frm']=Frm
  module Frm
    def self.new(layer_cfg=nil,site_cfg={})
      Msg.type?(site_cfg,Hash)
      if $opt.delete('l')
        site_cfg['host']='localhost'
        Sv.new(layer_cfg,site_cfg)
      elsif host=$opt['h']
        site_cfg['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(layer_cfg,site_cfg)
      else
        return Test.new(layer_cfg,site_cfg)
      end
      Cl.new(layer_cfg,site_cfg)
    end

    class Exe < Exe
      # site_cfg must have :db
      attr_reader :field,:flush_procs
      def initialize(layer_cfg=nil,site_cfg={})
        @cls_color=6
        @fdb=Msg.type?(site_cfg[:db],Db)
        site_cfg['id']=@fdb['id']
        @field=site_cfg[:field]=Field.new.set_db(@fdb)
        super
        @output=@field
        @cobj.add_intgrp(Int)
        # Post internal command procs
        # Proc for Terminate process of each individual commands
        @flush_procs=[]
      end
    end

    class Test < Exe
      def initialize(layer_cfg,site_cfg={})
        super
        @cobj.svdom.set_proc{|ent|@field['time']=now_msec;''}
        @cobj.ext_proc{|ent| "#{ent.cfg[:frame].inspect} => #{ent.cfg['response']}"}
        @cobj.item_proc('set'){|ent|
          @field.set(ent.par[0],ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
      end
    end

    class Cl < Exe
      def initialize(layer_cfg,site_cfg={})
        super
        host=type?(cfg['host']||@fdb['host']||'localhost',String)
        @field.ext_http(host)
        @cobj.svdom.set_proc{to_s}
        @pre_exe_procs << proc{@field.upd}
        ext_client(host,@fdb['port'])
      end
    end

    class Sv < Exe
      def initialize(layer_cfg,site_cfg={})
        super
        @field.ext_file
        timeout=5
        if $opt['s']
          @mode='SIM'
          iocmd=['devsim-file',@id,@fdb['version']]
          timeout=60
        else
          iocmd=@fdb['iocmd'].split(' ')
        end
        @stream=Stream.new(@id,@fdb['version'],iocmd,@fdb['wait'],timeout)
        @stream.ext_log unless $opt['s']
        @field.ext_rsp{@stream.rcv}
        @cobj.ext_proc{|ent|
          @stream.snd(ent.cfg[:frame],ent.id)
          @field.rsp(ent)
          'OK'
        }
        @cobj.item_proc('set'){|ent|
          @field.set(ent.par[0],ent.par[1])
          flush
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
        @cobj.item_proc('save'){|ent|
          @field.save_key(ent.par[0].split(','),ent.par[1])
          "Save [#{ent.par[0]}]"
        }
        @cobj.item_proc('load'){|ent|
          @field.load(ent.par[0]||'').save
          flush
          "Load [#{ent.par[0]}]"
        }
        ext_server(@fdb['port'].to_i)
      end

      private
      def flush
        @flush_procs.each{|p| p.call(self)}
        self
      end
    end

    if __FILE__ == $0
      require "libsh"
      require "libdevdb"
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      begin
        db=Dev::Db.new.set(id)
        Frm.new(nil,{:db => db}).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
