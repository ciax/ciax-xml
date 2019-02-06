#!/usr/bin/env ruby
require 'libfieldconv'
require 'libfrmcmd'
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
        # DB is generated in Dic level
        dbi = _init_dbi2cfg(%i(stream iocmd))
        @cfg[:site_id] = @id
        @stat = @cfg[:field] = Field.new(dbi)
        @sv_stat = Prompt.new(@id)
        _init_net
        ___init_command
        _opt_mode
      end

      def exe(args, src = 'local')
        super
      rescue CommError
        @sv_stat.up(:comerr)
        @sv_stat.seterr
        @stat.seterr
        raise
      end

      private

      # Mode Extension by Option
      def _ext_local
        @cobj.get('set').def_proc do |ent|
          @stat.repl(ent.par[0], ent.par[1])
          @stat.flush
          verbose { "Set [#{ent.par[0]}] = #{ent.par[1]}" }
        end
        super
      end

      def _ext_local_shell
        super.input_conv_set
      end

      def _ext_local_test
        @cobj.rem.ext.cfg[:def_msg] = 'TEST'
        super
      end

      def _ext_local_driver
        super
        require 'libfrmdrv'
        extend(Driver).ext_local_driver
      end

      # Sub Methods for Initialize
      def ___init_command
        @cobj.add_rem.cfg[:def_msg] = 'OK'
        @cobj.rem.add_sys
        @cobj.rem.add_ext
        @cobj.rem.add_int
        self
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
      ConfOpts.new('[id]', options: 'cehls') do |cfg|
        db = cfg[:db] = Dev::Db.new
        dbi = db.get(cfg.args.shift)
        eobj = Exe.new(cfg, dbi: dbi)
        if cfg.opt.sh?
          eobj.shell
        else
          puts eobj.exe(cfg.args).stat
        end
      end
    end
  end
end
