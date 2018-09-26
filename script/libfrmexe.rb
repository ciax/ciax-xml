#!/usr/bin/ruby
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
      def initialize(super_cfg, atrb = Hashx.new)
        super
        # DB is generated in List level
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

      def ext_shell
        super
        input_conv_set
        self
      end

      def ext_local_test
        @stat.ext_local_file
        @cobj.rem.ext.cfg[:def_msg] = 'TEST'
        super
      end

      def ext_local_driver
        require 'libfrmdrv'
        super
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
      def initialize(id)
        super('dev', id)
        init_flg(comerr: 'X', ioerr: 'E')
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        dbi = Dev::Db.new.get(args.shift)
        begin
          obj = Exe.new(cfg, dbi.pick)
          puts obj.exe(args).stat
        rescue CommError
          puts obj.stat
        end
      end
    end
  end
end
