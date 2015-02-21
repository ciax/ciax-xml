#!/usr/bin/ruby
require "libexe"
require "libfield"
require "libfrmdb"
require "libfrmrsp"
require "libfrmcmd"
require "libdevdb"

module CIAX
  $layers['f']=Frm
  module Frm
    def self.new(site_cfg,frm_cfg={})
      Msg.type?(frm_cfg,Hash)
      if $opt.delete('l')
        frm_cfg['host']='localhost'
        Sv.new(site_cfg,frm_cfg)
      elsif host=$opt['h']
        frm_cfg['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(site_cfg,frm_cfg)
      else
        return Test.new(site_cfg,frm_cfg)
      end
      Cl.new(site_cfg,frm_cfg)
    end

    class Exe < Exe
      # site_cfg must have 'id'
      attr_reader :field,:flush_procs
      def initialize(site_cfg,frm_cfg={})
        @cls_color=6
        if @fdb=frm_cfg[:db]
          site_cfg['id']=@fdb['id']
        else
          # LayerDB might generated in List level
          ddb=(site_cfg[:layer_db]||=Dev::Db.new)
          @fdb=type?(frm_cfg[:db]=ddb.set(site_cfg['id']),Db)
        end
        @field=frm_cfg[:field]=Field.new
        # Need cfg :db and :field
        super
        @output=@field.set_db(@fdb)
        @cobj.add_intgrp(Int)
        # Post internal command procs
        # Proc for Terminate process of each individual commands
        @flush_procs=[]
      end
    end

    class Test < Exe
      def initialize(site_cfg,frm_cfg={})
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
      def initialize(site_cfg,frm_cfg={})
        super
        host=type?(cfg['host']||@fdb['host']||'localhost',String)
        @field.ext_http(host)
        @cobj.svdom.set_proc{to_s}
        @pre_exe_procs << proc{@field.upd}
        ext_client(host,@fdb['port'])
      end
    end

    class Sv < Exe
      def initialize(site_cfg,frm_cfg={})
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
      cfg=Config.new('test',{'id' => ARGV.shift})
      begin
        Frm.new(cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
