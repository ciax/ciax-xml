#!/usr/bin/env ruby
# Ascii Pack
require 'libwatdic'
require 'libhexview'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    deep_include(CmdTree)
    # atrb must have [:dbi], [:sub_dic]
    class Exe < Exe
      def initialize(spcfg, atrb = Hashx.new)
        super
        _dbi_pick
        ___init_sub
        substat = SubStat.new(@sub_exe.sub_exe.stat, @sv_stat)
        @stat = View.new(substat, @cfg[:hdb])
        _opt_mode
      end

      private

      # Sub Methods for Initialize
      def ___init_sub
        @sub_exe = @cfg[:sub_dic].get(@id)
        @sv_stat = @sub_exe.sv_stat
        @cobj.add_rem(@sub_exe.cobj.rem)
        @mode = @sub_exe.mode
        @port = @sub_exe.sub_exe.port.to_i + 1000
        @post_exe_procs.concat(@sub_exe.post_exe_procs)
      end

      # Local mode
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        # Mode Extension by Option
        def run
          # Specific setting must be done after super to override them
          @server_input_proc = proc do |line|
            /^(strobe|stat)/ =~ line ? [] : line.split(' ')
          end
          @server_output_proc = proc { @stat.to_x }
          super
        end

        private

        def _ext_driver
          @stat.ext_log
          self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(cfg.args.shift)
        Exe.new(cfg, dbi: dbi, hdb: Db.new, sub_dic: Wat::ExeDic.new(cfg))
      end.cui
    end
  end
end
