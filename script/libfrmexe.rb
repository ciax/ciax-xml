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
        @cfg[:site_id] = id
        dbi = _init_dbi(id, %i(stream iocmd))
        @stat = @cfg[:field] = Field.new(dbi)
        @cobj.add_rem.add_sys
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
        _init_sub.add_flg(comerr: 'X', ioerr: 'E')
        # Post internal command procs
        @host ||= dbi[:host]
        @port ||= dbi[:port]
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
        sp = type?(@cfg[:stream], Hash)
        if @cfg[:option][:s]
          @mode = 'SIM'
          iocmd = [ENV['SIMCMD'] || 'frmsim', @id, @cfg[:version]]
          timeout = 60
        else
          @mode = 'DRV'
          iocmd = @cfg[:iocmd].split(' ')
          timeout = (sp[:timeout] || 10).to_i
        end
        @stream = Stream.new(@id, @cfg[:version], iocmd,
                             sp[:wait], timeout, esc_code(sp[:terminator]))
        @stream.ext_log if @cfg[:option].log?
        @stream.pre_open_proc = proc { @sv_stat.up(:ioerr) }
        @stream.post_open_proc = proc { @sv_stat.dw(:ioerr) }
        @stat.ext_rsp.ext_file.auto_save
        @cobj.rem.ext.def_proc do|ent, src|
          @sv_stat.dw(:comerr)
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

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new('ceh:lts')
      id = ARGV.shift
      cfg = Config.new(option: opt)
      begin
        Exe.new(id, cfg, db: Dev::Db.new).ext_shell.shell
      rescue InvalidID
        opt.usage('(opt) [id]')
      end
    end
  end
end
