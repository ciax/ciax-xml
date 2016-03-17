#!/usr/bin/ruby
require 'libexe'
require 'libsh'
require 'libfrmdb'
require 'libfrmrsp'
require 'libfrmcmd'
require 'libdevdb'

module CIAX
  # Frame Layer
  module Frm
    # Frame Exe module
    class Exe < Exe
      # cfg must have [:db]
      def initialize(id, cfg, atrb = {})
        super
        # DB is generated in List level
        dbi = _init_dbi(id, %i(stream iocmd))
        @cfg[:site_id] = id
        @stat = @cfg[:field] = Field.new(dbi)
        @sv_stat = Prompt.new('dev', id).add_flg(comerr: 'X', ioerr: 'E')
        init_server(dbi)
        init_command
        _opt_mode
      end

      def exe(args, src = 'local', pri = 1)
        super
      rescue CommError
        @sv_stat.up(:comerr)
        @sv_stat.rep(:msg, $ERROR_INFO.to_s)
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

      def init_server(dbi)
        @host = @cfg[:option].host || dbi[:host]
        @port ||= dbi[:port]
        self
      end

      def init_command
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
          @stat.rep(ent.par[0], ent.par[1])
          ent.msg = "Set [#{ent.par[0]}] = #{ent.par[1]}"
        end
      end

      def ext_driver
        _init_stream
        @stat.ext_rsp.ext_file.auto_save
        _init_drv_ext
        _init_drv_save
        _init_drv_load
        _init_drv_set
        _init_drv_flush
        super
      end

      def _init_stream
        @stream = Stream.new(@id, @cfg)
        @stream.ext_log if @cfg[:option].log?
        @stream.pre_open_proc = proc { @sv_stat.up(:ioerr) }
        @stream.post_open_proc = proc { @sv_stat.dw(:ioerr) }
      end

      def _init_drv_ext
        @cobj.rem.ext.def_proc do|ent, src|
          @sv_stat.dw(:comerr)
          @stream.snd(ent[:frame], ent.id)
          @stat.conv(ent, @stream.rcv) if ent[:response]
          @stat.flush if src != 'buffer'
          ent.msg = 'OK'
        end
      end

      def _init_drv_save
        @cobj.get('save').def_proc do|ent|
          @stat.save_key(ent.par[0].split(','), ent.par[1])
          ent.msg = "Save [#{ent.par[0]}]"
        end
      end

      def _init_drv_load
        @cobj.get('load').def_proc do|ent|
          @stat.load(ent.par[0] || '')
          @stat.flush
          ent.msg = "Load [#{ent.par[0]}]"
        end
      end

      def _init_drv_set
        @cobj.get('set').def_proc do|ent|
          @stat.rep(ent.par[0], ent.par[1])
          @stat.flush
          ent.msg = "Set [#{ent.par[0]}] = #{ent.par[1]}"
        end
      end

      def _init_drv_flush
        @cobj.get('flush').def_proc do
          @stream.rcv
          @stat.flush
          ent.msg = 'Flush Stream'
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        Exe.new(args.shift, cfg, db: Dev::Db.new).ext_shell.shell
      end
    end
  end
end
