#!/usr/bin/env ruby
require 'libfrmconv'
require 'libfrmcmd'
require 'libframe'
require 'libdevdb'
require 'libexelocal'

module CIAX
  # Frame Layer
  module Frm
    # Frame Exe module
    class Exe < Exe
      # atrb must have [:dbi]
      def initialize(spcfg, atrb = Hashx.new)
        super
        # DB is generated in ExeDic level
        @cfg[:site_id] = @id
        _init_port
        ___init_stat
        ___init_command
        _opt_mode
      end

      def exe(args, src = 'local')
        super
      rescue CommError
        @sv_stat.up(:comerr)
        @sv_stat.seterr
        @stat.comerr
        raise
      end

      private

      def _ext_remote
        super
        _remote_sv_stat
        _remote_stat
        self
      end

      def _ext_shell
        super.input_conv_set
      end

      def ___init_stat
        _dbi_pick(:stream, :iocmd)
        @stat = Field.new(@dbi)
        @frame = @stat.sub_stat
        @sv_stat = Prompt.new(@id)
        @stat_pool = StatPool.new(@stat)
        @cfg.update(stat_pool: @stat_pool, sv_stat: @sv_stat)
      end

      # Sub Methods for Initialize
      def ___init_command
        @cobj.add_rem.cfg[:def_msg] = 'OK'
        @cobj.rem.add_sys if @frame
        @cobj.rem.add_ext
        @cobj.rem.add_int
        self
      end

      # Local mode
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        # Mode Extension by Option
        def ext_local
          @frame.ext_local.ext_file if @frame
          _set_def_proc('set') do |ent|
            key, val = ent.par
            @stat.repl(key, val)
            @stat.flush
            verbose { "Set [#{key}] = #{val}" }
          end
          super
        end

        def run
          super
          @sv_stat.ext_local.ext_file.ext_save.ext_log
          self
        end

        private

        def _ext_test
          @cobj.rem.ext.cfg[:def_msg] = 'TEST'
          super
        end

        def _ext_driver
          super
          require 'libfrmdrv'
          extend(Driver).ext_driver
        end
      end
    end

    # To distinct from other(site) proc array title
    class Prompt < Prompt
      # commerr: device no response
      # ioerr: port is not open (communication refused)
      def initialize(id)
        super('dev', id)
        init_flg(comerr: 'X', ioerr: 'E')
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        db = cfg[:db] = Dev::Db.new
        dbi = db.get(cfg.args.shift)
        Exe.new(cfg, dbi: dbi)
      end.cui
    end
  end
end
