#!/usr/bin/ruby
require "libexe"
require "libfield"
require "libfrmdb"
require "libfrmrsp"
require "libfrmcmd"

module CIAX
  $layers['frm']=Frm
  module Frm
    # site_cfg should have :fdb(Frm::Db)
    def self.new(site_cfg,attr={})
      Msg.type?(site_cfg,Hash)
      if $opt.delete('l')
        attr['host']='localhost'
        Sv.new(site_cfg,attr)
      elsif host=$opt['h']
        attr['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(site_cfg,attr)
      else
        return Test.new(site_cfg,attr)
      end
      Cl.new(site_cfg,attr)
    end

    class Exe < Exe
      # site_cfg must have 'id',:site_db
      attr_reader :field,:flush_procs
      def initialize(site_cfg,attr={})
        @cls_color=6
        @fdb=attr[:db]=type?(site_cfg[:site_db][:fdb],Db)
        @field=attr[:field]=Field.new.set_db(@fdb)
        super
        @output=@field
        @cobj.add_intgrp(Int)
        # Post internal command procs
        # Proc for Terminate process of each individual commands
        @flush_procs=[]
      end
    end

    class Test < Exe
      def initialize(site_cfg,attr={})
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
      def initialize(site_cfg,attr={})
        super
        host=type?(cfg['host']||@fdb['host']||'localhost',String)
        @field.ext_http(host)
        @cobj.svdom.set_proc{to_s}
        @pre_exe_procs << proc{@field.upd}
        ext_client(host,@fdb['port'])
      end
    end

    class Sv < Exe
      def initialize(site_cfg,attr={})
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
      require "libsitelist"
      require "libsh"
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      begin
        Site::List.new('frm').ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
