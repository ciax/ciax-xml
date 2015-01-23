#!/usr/bin/ruby
require 'libsh'
require 'libfield'
require "libfrmrsp"
require "libfrmcmd"
require 'libsitelist'

module CIAX
  module Frm
    # cfg should have :db(Frm::Db)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      cfg['iocmd']=['devsim-file',cfg[:db]['site_id'],cfg[:db]['stream_ver']] if $opt['s']
      if $opt.delete('l')
        cfg['host']='localhost'
        Sv.new(cfg)
      elsif host=$opt.delete('h')
        cfg['host']=host
      elsif $opt.delete('c')
      elsif $opt['s'] or $opt['e']
        return Sv.new(cfg)
      else
        return Test.new(cfg)
      end
      Cl.new(cfg)
    end

    class Jump < LongJump; end

    class Exe < Exe
      attr_reader :field,:flush_procs
      def initialize(cfg)
        @fdb=type?(cfg[:db],Db)
        @field=cfg[:field]=Field.new.set_db(@fdb)
        @cls_color=6
        super('frm',@field['id'],Command.new(cfg))
        @output=@field
        @cobj.add_int
        @flush_procs=[] # Proc for Terminate process of Batch
        ext_shell
      end
    end

    class Test < Exe
      def initialize(cfg)
        super
        @mode='TEST'
        @cobj.svdom.set_proc{|ent|@field['time']=now_msec;''}
        @cobj.ext_proc{|ent| "#{ent.cfg[:frame].inspect} => #{ent.cfg['response']}"}
        @cobj.item_proc('set'){|ent|
          @field.set(ent.par[0],ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super(cfg)
        host=type?(cfg['host']||@fdb['host']||'localhost',String)
        @field.ext_http(host)
        @cobj.svdom.set_proc{to_s}
        @pre_exe_procs << proc{@field.upd}
        ext_client(host,@fdb['port'])
      end
    end

    class Sv < Exe
      def initialize(cfg)
        super(cfg)
        @field.ext_file
        timeout=5
        if sim=cfg['iocmd']
          @mode='SIM'
          timeout=60
        end
        iocmd= sim ? type?(sim,Array) : @fdb['iocmd'].split(' ')
        @stream=Stream.new(@id,@fdb['stream_ver'],iocmd,@fdb['wait'],timeout)
        @stream.ext_log unless sim
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

    class List < Site::List
      def initialize(upper=nil)
        super(Frm,upper)
        @cfg.layers[:frm]=self
      end

      def add(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:fdb]
        set(id,Frm.new(@cfg))
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
