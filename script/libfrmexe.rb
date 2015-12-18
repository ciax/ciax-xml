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
  # Frame Layer
  module Frm
    # Frame Exe module
    class Exe < Exe
      # cfg must have [:db]
      def initialize(id, cfg)
        super(id, cfg)
        # DB is generated in List level
        @cfg[:site_id] = id
        @cfg[:ver] = @dbi['version']
        @stat = @cfg[:field] = Field.new(@dbi)
        @cobj.add_rem.add_sys
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
        @sv_stat.add_flg(comerr: 'X', strerr: 'E')
        # Post internal command procs
        @host ||= @dbi['host']
        @port ||= @dbi['port']
        opt_mode
      end

      def exe(args, src = 'local', pri = 1)
        super
      rescue CommError
        @sv_stat.set(:comerr).msg($ERROR_INFO.to_s)
        @stat.seterr
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
        @stat.ext_file
        @cobj.rem.ext.def_proc { 'TEST' }
        @cobj.get('set').def_proc do|ent|
          @stat.rep(ent.par[0], ent.par[1])
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        end
        self
      end

      def ext_driver
        sp = @dbi[:stream]
        if OPT[:s]
          @mode = 'SIM'
          iocmd = [SIMCMD, @id, @dbi['version']]
          timeout = 60
        else
          @mode = 'DRV'
          iocmd = @dbi[:iocmd].split(' ')
          timeout = (sp[:timeout] || 10).to_i
        end
        @stream = Stream.new(@id, @dbi[:version], iocmd,
                             sp[:wait], timeout, esc_code(sp[:terminator]))
        @stream.ext_log unless OPT[:s]
        @stream.pre_open_proc = proc { @sv_stat.set(:strerr) }
        @stream.post_open_proc = proc { @sv_stat.reset(:strerr) }
        @stat.ext_rsp.ext_file.auto_save
        @cobj.rem.ext.def_proc do|ent, src|
          @sv_stat.reset(:comerr)
          @stream.snd(ent[:frame], ent.id)
          @stat.conv(ent, @stream.rcv) if ent[:response]
          @stat.flush if src != 'buffer'
          'OK'
        end
        @cobj.get('set').def_proc do|ent|
          @stat.rep(ent.par[0], ent.par[1])
          @stat.flush
          "Set [#{ent.par[0]}] = #{ent.par[1]}"
        end
        @cobj.get('save').def_proc do|ent|
          @stat.save_key(ent.par[0].split(','), ent.par[1])
          "Save [#{ent.par[0]}]"
        end
        @cobj.get('load').def_proc do|ent|
          @stat.load(ent.par[0] || '')
          @stat.flush
          "Load [#{ent.par[0]}]"
        end
        @cobj.get('flush').def_proc do
          @stream.rcv
          @stat.flush
          'Flush Stream'
        end
        self
      end
    end

    # Frame List module
    class List < Site::List
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self)
        store_db(Dev::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('ceh:lts')
      cfg = Config.new
      cfg[:jump_groups] = []
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
