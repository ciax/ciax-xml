#!/usr/bin/ruby
require 'libsh'
require 'libfrmdrv'
require 'libfrmrsp'
require 'libfrmcmd'
require 'libdevdb'

module CIAX
  # Frame Layer
  module Frm
    # Frame Exe module
    class Exe < Exe
      # cfg must have [:db]
      def initialize(cfg, atrb = Hashx.new)
        super
        # DB is generated in List level
        dbi = _init_dbi(%i(stream iocmd))
        @cfg[:site_id] = id
        @stat = @cfg[:field] = Field.new(dbi)
        @sv_stat = Prompt.new(id)
        _init_net(dbi)
        _init_command
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

      def ext_shell
        super
        @cfg[:output] = @stat
        input_conv_set
        self
      end

      private

      # Initialize Subroutine
      def _init_net(dbi)
        @host = @cfg[:opt].host || dbi[:host]
        @port ||= dbi[:port]
        self
      end

      def _init_command
        @cobj.add_rem.cfg[:def_msg] = 'OK'
        @cobj.rem.add_sys
        @cobj.rem.add_ext
        @cobj.rem.add_int
        self
      end

      # Mode Extension
      def ext_local_test
        @stat.ext_local_file
        @cobj.rem.ext.cfg[:def_msg] = 'TEST'
        super
      end

      def ext_local
        @cobj.get('set').def_proc do |ent|
          @stat.repl(ent.par[0], ent.par[1])
          @stat.flush
          verbose { "Set [#{ent.par[0]}] = #{ent.par[1]}" }
        end
        super
      end

      def ext_local_driver
        super
        extend(Drv).ext_local_driver
      end
    end

    # For Frm
    class Prompt < Prompt
      def initialize(id)
        super('dev', id)
        init_flg(comerr: 'X', ioerr: 'E')
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        dbi = Dev::Db.new.get(args.shift)
        Exe.new(cfg, dbi: dbi).ext_shell.shell
      end
    end
  end
end
