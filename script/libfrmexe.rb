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
    def self.new(id,cfg,attr={})
      if $opt.sv?
        Sv.new(id,cfg,attr)
      elsif $opt.cl?
        Cl.new(id,cfg,attr.update($opt.host))
      else
        Test.new(id,cfg,attr)
      end
    end

    class Exe < Exe
      # cfg must have [:db]
      attr_reader :field,:flush_procs
      def initialize(id,cfg,attr={})
        super
        # DB is generated in List level
        @cfg[:site_id]=id
        @fdb=type?(@cfg[:db].get(id),Dbi)
        @cfg['ver']=@fdb['version']
        @field=@cfg[:field]=Field.new.set_db(@fdb)
        @cobj=Index.new(@cfg)
        @cobj.add_rem.add_hid
        @cobj.rem.add_int
        @cobj.rem.add_ext(@fdb)
        # Post internal command procs
        # Proc for Terminate process of each individual commands
        @flush_procs=[]
        @cfg['host']||=@fdb['host']
        @cfg['port']||=@fdb['port']
      end

      def ext_shell
        super
        @cfg[:output]=@field
        @post_exe_procs << proc{|args,src|
          flush if !args.empty? and src != 'local'
        }
        input_conv_set
        self
      end

      private
      def flush
        @flush_procs.each{|p| p.call(self)}
        self
      end
    end

    class Test < Exe
      def initialize(id,cfg,attr={})
        super
        @field.ext_file
        @cobj.rem.def_proc{|ent|@field['time']=now_msec;''}
        @cobj.rem.ext.def_proc{|ent| ent.cfg.path }
        @cobj.get('set').def_proc{|ent|
          @field.rep(ent.par[0],ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
      end
    end

    class Cl < Exe
      def initialize(id,cfg,attr={})
        super
        @field.ext_http(@cfg['host'])
        @cobj.rem.def_proc{to_s}
        @pre_exe_procs << proc{@field.upd}
        ext_client
      end
    end

    class Sv < Exe
      def initialize(id,cfg,attr={})
        super
        @field.ext_file
        @site_stat.add_db('comerr' => 'X','strerr' => 'E')
        if $opt['s']
          @mode='SIM'
          iocmd=['devsim-file',@id,@fdb['version']]
          timeout=60
        else
          iocmd=@fdb['iocmd'].split(' ')
          timeout=(@fdb['timeout']||10).to_i
        end
        tm=@fdb[:response][:frame]["terminator"]
        @stream=Stream.new(@id,@fdb['version'],iocmd,@fdb['wait'],timeout,(tm && eval('"'+tm+'"')))
        @stream.ext_log unless $opt['s']
        @stream.pre_open_proc=proc{@site_stat.set('strerr')}
        @stream.post_open_proc=proc{@site_stat.reset('strerr')}
        @field.ext_rsp{@stream.rcv}
        @cobj.rem.ext.def_proc{|ent|
          @site_stat.reset('comerr')
          @stream.snd(ent.cfg[:frame],ent.id)
          @field.conv(ent)
          'OK'
        }
        @cobj.get('set').def_proc{|ent|
          @field.rep(ent.par[0],ent.par[1])
          flush
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
        @cobj.get('save').def_proc{|ent|
          @field.save_key(ent.par[0].split(','),ent.par[1])
          "Save [#{ent.par[0]}]"
        }
        @cobj.get('load').def_proc{|ent|
          @field.load(ent.par[0]||'').save
          flush
          "Load [#{ent.par[0]}]"
        }
        @cobj.get('flush').def_proc{|ent|
          @stream.rcv
          flush
          "Flush Stream"
        }
      end

      def exe(args,src='local',pri=1)
        super
      rescue CommError
        @site_stat.set('comerr')
        self['msg']=$!.to_s
        raise $!
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
      GetOpts.new('ceh:lts')
      cfg=Config.new
      cfg[:site]=ARGV.shift
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
