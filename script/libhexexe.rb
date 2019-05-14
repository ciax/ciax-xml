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
        @sub_exe = ___init_sub
        @stat = View.new(@sub_exe.stat, @cfg[:hdb])
        @port = @port.to_i + 1000
        _opt_mode
      end

      private

      # Sub Methods for Initialize
      def ___init_sub
        se = @cfg[:sub_dic].get(@id)
        @sv_stat = se.sv_stat
        @cobj.add_rem(se.cobj.rem)
        @mode = se.mode
        @port = se.port
        @post_exe_procs.concat(se.post_exe_procs)
        se
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
