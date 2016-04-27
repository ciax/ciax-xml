#!/usr/bin/ruby
# Ascii Pack
require 'libwatlist'
require 'libhexrsp'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    # cfg must have [:db], [:sub_list]
    class Exe < Exe
      def initialize(id, cfg, atrb = Hashx.new)
        super
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
        @stat.ext_log if @cfg[:option].log?
      end

      def ext_server
        super
        # Specific setting must be done after super to override them
        @server_input_proc = proc do|line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = @shell_output_proc
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        atrb = { hdb: Db.new, sub_list: Wat::List.new(cfg) }
        Exe.new(args.shift, cfg, atrb).ext_shell.shell
      end
    end
  end
end
