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
        Exe.new(id,cfg,attr.update($opt.host)).ext_client
      else
        Exe.new(id,cfg,attr).ext_sv
      end
    end

    class Exe < Exe
      # cfg must have [:db]
      attr_reader :field,:flush_procs
      def initialize(id,cfg,attr={})
        super
        # DB is generated in List level
        @cfg[:site_id]=id
        @cfg['ver']=@dbi['version']
        @field=@cfg[:field]=Field.new.set_db(@dbi)
        @cobj.add_rem
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
        # Post internal command procs
        # Proc for Terminate process of each individual commands
        @flush_procs=[]
        @cfg['host']||=@dbi['host']
        @cfg['port']||=@dbi['port']
      end

      def ext_client
        @field.ext_http(@cfg['host'])
        @pre_exe_procs << proc{@field.upd}
        super
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

      def ext_sv
        @field.ext_file
        @cobj.rem.add_hid
        @cobj.rem.def_proc{|ent|@field['time']=now_msec;''}
        @cobj.rem.ext.def_proc{|ent| ent.cfg.path }
        @cobj.get('set').def_proc{|ent|
          @field.rep(ent.par[0],ent.par[1])
          flush
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
        self
      end

      private
      def flush
        @flush_procs.each{|p| p.call(self)}
        self
      end
    end

    class Sv < Exe
      def initialize(id,cfg,attr={})
        super
        ext_sv
        @site_stat.add_db('comerr' => 'X','strerr' => 'E')
        if $opt['s']
          @mode='SIM'
          iocmd=['devsim-file',@id,@dbi['version']]
          timeout=60
        else
          @mode='SV'
          iocmd=@dbi['iocmd'].split(' ')
          timeout=(@dbi['timeout']||10).to_i
        end
        tm=@dbi[:response][:frame]["terminator"]
        @stream=Stream.new(@id,@dbi['version'],iocmd,@dbi['wait'],timeout,(tm && eval('"'+tm+'"')))
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
        @site_stat.set('comerr').msg($!.to_s)
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
