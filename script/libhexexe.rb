#!/usr/bin/ruby
# Ascii Pack
require 'libwatlist'
require 'libhexview'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    deep_include(CmdTree)
    # atrb must have [:dbi], [:sub_list]
    class Exe < Exe
      def initialize(super_cfg, atrb = Hashx.new)
        super
        _init_dbi2cfg
        ___init_sub
        ___init_view
        _opt_mode
      end

      # Mode Extension by Option
      def ext_local_server
        # Specific setting must be done after super to override them
        @server_input_proc = proc do |line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = @shell_output_proc
        super
      end

      # Dummy
      def ext_local_driver
        ext_local_server if @opt.sv?
        self
      end

      private

      # Sub Methods for Initialize
      def ___init_sub
        @sub = @cfg[:sub_list].get(@id)
        @sv_stat = @sub.sv_stat
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @port = @sub.sub.port.to_i + 1000
        @post_exe_procs.concat(@sub.post_exe_procs)
      end

      def ___init_view
        @stat = View.new(@sub.sub.stat, @cfg[:hdb], @sv_stat)
        @shell_output_proc = proc { @stat.to_x }
        @stat.ext_local_log if @opt.drv?
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(args.shift)
        atrb = { dbi: dbi, hdb: Db.new, sub_list: Wat::List.new(cfg) }
        Exe.new(cfg, atrb).ext_shell.shell
      end
    end
  end
end
