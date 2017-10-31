#!/usr/bin/ruby
# Ascii Pack
require 'libwatlist'
require 'libhexrsp'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    Msg.deep_include(Hex, CmdTree)
    # cfg must have [:db], [:sub_list]
    class Exe < Exe
      def initialize(cfg, atrb = Hashx.new)
        super
        _init_dbi
        _init_takeover
        _init_view
        _opt_mode
      end

      private

      def _init_takeover
        @sub = @cfg[:sub_list].get(@id)
        @sv_stat = @sub.sv_stat
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @port = @sub.sub.port.to_i + 1000
        @post_exe_procs.concat(@sub.post_exe_procs)
      end

      def _init_view
        @stat = Rsp.new(@sub.sub.stat, @cfg[:hdb], @sv_stat)
        @shell_output_proc = proc { @stat.to_x }
        @stat.ext_local_log if @cfg[:opt].log?
      end

      def ext_local_server
        super
        # Specific setting must be done after super to override them
        @server_input_proc = proc do |line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = @shell_output_proc
        self
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
