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
    def self.new(id,inter_cfg={},attr={})
      Msg.type?(attr,Hash)
      if $opt.delete('l')
        attr['host']='localhost'
        Sv.new(id,inter_cfg,attr)
      elsif host=$opt['h']
        attr['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(id,inter_cfg,attr)
      else
        return Test.new(id,inter_cfg,attr)
      end
      Cl.new(id,inter_cfg,attr)
    end

    class Exe < Exe
      # inter_cfg must have 'id'
      attr_reader :field,:flush_procs
      def initialize(id,inter_cfg={},attr={})
        @cls_color=6
        # LayerDB might generated in List level
        ddb=(inter_cfg[:layer_db]||=Dev::Db.new)
        @fdb=type?(attr[:db]=ddb.get(id),Dbi)
        @field=attr[:field]=Field.new
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
      def initialize(id,inter_cfg={},attr={})
        super
        @cobj.rem.cfg.proc{|ent|@field['time']=now_msec;''}
        @cobj.ext_proc{|ent| "#{ent.cfg[:frame].inspect} => #{ent.cfg['response']}"}
        @cobj.item_proc('set'){|ent|
          @field.rep(ent.par[0],ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
      end
    end

    class Cl < Exe
      def initialize(id,inter_cfg={},attr={})
        super
        host=type?(cfg['host']||@fdb['host']||'localhost',String)
        @field.ext_http(host)
        @cobj.rem.cfg.proc{to_s}
        @pre_exe_procs << proc{@field.upd}
        ext_client(host,@fdb['port'])
      end
    end

    class Sv < Exe
      def initialize(id,inter_cfg={},attr={})
        super
        @field.ext_file
        @site_stat.add_db('comerr' => 'X','strerr' => 'E')
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
        @stream.pre_open_proc=proc{@site_stat['strerr']=true}
        @stream.post_open_proc=proc{@site_stat['strerr']=false}
        @field.ext_rsp{@stream.rcv}
        @cobj.ext_proc{|ent|
          @site_stat['comerr']=false
          @stream.snd(ent.cfg[:frame],ent.id)
          @field.rsp(ent)
          'OK'
        }
        @cobj.item_proc('set'){|ent|
          @field.rep(ent.par[0],ent.par[1])
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

      def exe(args,src='local',pri=1)
        super
      rescue CommError
        @site_stat['comerr']=true
        self['msg']=$!.to_s
        raise $!
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
      begin
        Frm.new(ARGV.shift).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
