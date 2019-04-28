#!/usr/bin/env ruby
require 'libfrmconv'
require 'libfrmcmd'
require 'libframe'
require 'libdevdb'
require 'libexe'

module CIAX
  # Frame Layer
  module Frm
    # Frame Exe module
    class Exe < Exe
      # atrb must have [:dbi]
      def initialize(spcfg, atrb = Hashx.new)
        super
        # DB is generated in ExeDic level
        dbi = _init_dbi2cfg(%i(stream iocmd))
        @cfg[:site_id] = @id
        @stat = @cfg[:field] = Field.new(dbi)
        @frame = @stat.frame
        @sv_stat = @cfg[:sv_stat] = Prompt.new(@id)
        _init_net
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

      def _ext_shell
        super.input_conv_set
      end

      # Sub Methods for Initialize
      def ___init_command
        @cobj.add_rem.cfg[:def_msg] = 'OK'
        @cobj.rem.add_sys
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
          @cobj.get('set').def_proc do |ent|
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

    # For Frm
    class Prompt < Prompt
      # commerr: device no response
      # ioerr: port is not open (communication refused)
      def initialize(id)
        super('dev', id)
        init_flg(comerr: 'X', ioerr: 'E')
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libexedic'
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        db = cfg[:db] = Dev::Db.new
        dbi = db.get(cfg.args.shift)
        Exe.new(cfg, dbi: dbi)
      end.cui
    end
  end
end
