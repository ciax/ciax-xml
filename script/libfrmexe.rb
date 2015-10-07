#!/usr/bin/ruby
require 'libexe'
require 'libsh'
require 'libfield'
require 'libfrmdb'
require 'libfrmrsp'
require 'libfrmcmd'
require 'libdevdb'
require 'libsitelist'

module CIAX
  module Frm
    class Exe < Exe
      # cfg must have [:db]
      def initialize(id, cfg)
        super(id, cfg)
        # DB is generated in List level
        @cfg[:site_id] = id
        @cfg['ver'] = @dbi['version']
        @stat = @cfg[:field] = Field.new.setdbi(@dbi)
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
        # Post internal command procs
        @host ||= @dbi['host']
        @port ||= @dbi['port']
        opt_mode
      end

      def exe(args, src = 'local', pri = 1)
        super
      rescue CommError
        @sv_stat.set('comerr').msg($ERROR_INFO.to_s)
        raise $ERROR_INFO
      end

      def ext_shell
        super
        @cfg[:output] = @stat
        input_conv_set
        self
      end

      private
      def ext_test
        @mode = 'TEST'
        @stat.ext_save.ext_load
        @cobj.rem.ext.def_proc { 'TEST' }
        @cobj.get('set').def_proc{|ent|
          @stat.rep(ent.par[0], ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
        self
      end

      def ext_driver
        if OPT['s']
          @mode = 'SIM'
          iocmd = ['devsim-file', @id, @dbi['version']]
          timeout = 60
        else
          @mode = 'DRV'
          iocmd = @dbi['iocmd'].split(' ')
          timeout = (@dbi['timeout'] || 10).to_i
        end
        tm = @dbi[:response][:frame]['terminator']
        @stream = Stream.new(@id, @dbi['version'], iocmd, @dbi['wait'], timeout, (tm && eval('"' + tm + '"')))
        @stream.ext_log unless OPT['s']
        @stream.pre_open_proc = proc { @sv_stat.set('strerr') }
        @stream.post_open_proc = proc { @sv_stat.reset('strerr') }
        @sv_stat.add_db('comerr' => 'X', 'strerr' => 'E')
        @stat.ext_save.ext_load
        @stat.ext_rsp { @stream.rcv }
        @cobj.rem.ext.def_proc{|ent, src|
          @sv_stat.reset('comerr')
          @stream.snd(ent[:frame], ent.id)
          @stat.conv(ent)
          @stat.flush if src != 'buffer'
          'OK'
        }
        @cobj.get('set').def_proc{|ent|
          @stat.rep(ent.par[0], ent.par[1])
          @stat.flush
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        }
        @cobj.get('save').def_proc{|ent|
          @stat.save_key(ent.par[0].split(','), ent.par[1])
          "Save [#{ent.par[0]}]"
        }
        @cobj.get('load').def_proc{|ent|
          @stat.load(ent.par[0] || '')
          @stat.flush
          "Load [#{ent.par[0]}]"
        }
        @cobj.get('flush').def_proc{
          @stream.rcv
          @stat.flush
          'Flush Stream'
        }
        self
      end

    end

    class List < Site::List
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self)
        set_db(Dev::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ENV['VER'] ||= 'initialize'
      OPT.parse('ceh:lts')
      cfg = Config.new
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
