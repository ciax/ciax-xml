#!/usr/bin/ruby
# Ascii Pack
require 'libwatdic'
require 'libhexview'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    deep_include(CmdTree)
    # atrb must have [:dbi], [:sub_dic]
    class Exe < Exe
      def initialize(super_cfg, atrb = Hashx.new)
        super
        _init_dbi2cfg
        ___init_sub
        @stat = View.new(@sub.sub.stat, @cfg[:hdb], @sv_stat)
        _opt_mode
      end

      # Mode Extension by Option
      def run
        # Specific setting must be done after super to override them
        @server_input_proc = proc do |line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = proc { @stat.to_s }
        super
      end

      private

      # Sub Methods for Initialize
      def ___init_sub
        @sub = @cfg[:sub_dic].get(@id)
        @sv_stat = @sub.sv_stat
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @port = @sub.sub.port.to_i + 1000
        @post_exe_procs.concat(@sub.post_exe_procs)
      end

      def _ext_local_driver
        @stat.ext_local_log
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(args.shift)
        atrb = { dbi: dbi, hdb: Db.new, sub_dic: Wat::Dic.new(cfg) }
        Exe.new(cfg, atrb).shell
      end
    end
  end
end
