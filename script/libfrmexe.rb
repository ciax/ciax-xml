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
      def initialize(id, cfg, atrb = Hashx.new)
        super
        # DB is generated in List level
        dbi = _init_dbi(id, %i(stream iocmd))
        @cfg[:site_id] = id
        @stat = @cfg[:field] = Field.new(dbi)
        @sv_stat = Prompt.new('dev', id).add_flg(comerr: 'X', ioerr: 'E')
        _init_net(dbi)
        _init_command
        _opt_mode
      end

      def exe(args, src = 'local', pri = 1)
        super
      rescue CommError
        @sv_stat.up(:comerr)
        @sv_stat.repl(:msg, $ERROR_INFO.to_s)
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

      def _init_net(dbi)
        @host = @cfg[:option].host || dbi[:host]
        @port ||= dbi[:port]
        self
      end

      def _init_command
        @cobj.add_rem.add_sys
        @cobj.rem.add_ext(Ext)
        @cobj.rem.add_int(Int)
        self
      end

      def ext_test
        @stat.ext_file
        @cobj.rem.ext.def_proc { |ent| ent.msg = 'TEST' }
        _init_test_set
        super
      end

      def _init_test_set
        @cobj.get('set').def_proc do|ent|
          @stat.repl(ent.par[0], ent.par[1])
          ent.msg = "Set [#{ent.par[0]}] = #{ent.par[1]}"
        end
      end

      def ext_driver
        super
        extend(Drv).ext_driver
      end
    end

    class Prompt < Prompt; end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        Exe.new(args.shift, cfg, db: Dev::Db.new).ext_shell.shell
      end
    end
  end
end
