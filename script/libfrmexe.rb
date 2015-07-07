#!/usr/bin/ruby
require "libexe"
require "libsh"
require "libfield"
require "libfrmdb"
require "libfrmrsp"
require "libfrmcmd"
require "libdevdb"
require "libsitelist"

module CIAX
  module Frm
    def self.new(id,cfg={},attr={})
      Msg.type?(attr,Hash)
      if $opt.delete('l')
        attr['host']='localhost'
        Sv.new(id,cfg,attr)
      elsif host=$opt['h']
        attr['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(id,cfg,attr)
      else
        return Test.new(id,cfg,attr)
      end
      Cl.new(id,cfg,attr)
    end

    class Exe < Exe
      # cfg must have [:db]
      attr_reader :field,:flush_procs
      def initialize(id,cfg={},attr={})
        super
        # DB is generated in List level
        @cfg[:site_id]=id
        @fdb=type?(@cfg[:db].get(id),Dbi)
        @cfg['ver']=@fdb['version']
        @field=@cfg[:field]=Field.new.set_db(@fdb)
        @cobj=Index.new(@cfg)
        @cobj.add_rem
        @cobj.rem.add_hid
        @cobj.rem.add_ext(@fdb)
        @cobj.rem.add_int
        # Post internal command procs
        # Proc for Terminate process of each individual commands
        @flush_procs=[]
        @cfg['host']||=@fdb['host']
        @cfg['port']||=@fdb['port']
      end

      def ext_shell
        @output=@field
        super
      end
    end

    class Test < Exe
      def initialize(id,cfg={},attr={})
        super
        @cobj.rem.proc{|ent|@field['time']=now_msec;''}
        @cobj.rem.ext.proc{|ent| ent.cfg.path }
        @cobj.rem.int['set'].proc{|ent|
          @field.rep(ent.par[0],ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
      end
    end

    class Cl < Exe
      def initialize(id,cfg={},attr={})
        super
        host=type?(@cfg['host']||@fdb['host']||'localhost',String)
        @field.ext_http(host)
        @cobj.rem.proc{to_s}
        @pre_exe_procs << proc{@field.upd}
        ext_client
      end
    end

    class Sv < Exe
      def initialize(id,cfg={},attr={})
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
        @cobj.rem.ext.proc{|ent|
          @site_stat['comerr']=false
          @stream.snd(ent.cfg[:frame],ent.id)
          @field.conv(ent)
          'OK'
        }
        @cobj.rem.int['set'].proc{|ent|
          @field.rep(ent.par[0],ent.par[1])
          flush
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
        @cobj.rem.int['save'].proc{|ent|
          @field.save_key(ent.par[0].split(','),ent.par[1])
          "Save [#{ent.par[0]}]"
        }
        @cobj.rem.int['load'].proc{|ent|
          @field.load(ent.par[0]||'').save
          flush
          "Load [#{ent.par[0]}]"
        }
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

    class List < Site::List
      def initialize(cfg,attr={})
        super
        set_db(Dev::Db.new)
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      cfg=Config.new
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
