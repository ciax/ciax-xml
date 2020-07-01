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
        @sub_exe = _init_sub_exe
        @stat_pool = @sub_exe.stat_pool
        @stat = View.new(@stat_pool, @cfg[:hdb])
        _init_port(1000)
        _opt_mode
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
          @stat.ext_local.ext_log
          self
        end
      end
    end

    if $PROGRAM_NAME == __FILE__
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(cfg.args.shift)
        sub_dic = Wat::ExeDic.new(cfg)
        Exe.new(cfg, dbi: dbi, sub_dic: sub_dic, hdb: Db.new)
      end.cui
    end
  end
end
