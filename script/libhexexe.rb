#!/usr/bin/ruby
# Ascii Pack
require 'libwatlist'
require 'libhexrsp'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    # cfg must have [:db], [:sub_list]
    class Exe < Exe
      def initialize(id, cfg, atrb = {})
        super
        @sub = @cfg[:sub_list].get(id)
        @sv_stat = @sub.sv_stat
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @port = @sub.sub.port.to_i + 1000
        @post_exe_procs.concat(@sub.post_exe_procs)
        _init_view
      end

      private

      def _init_view
        view = Rsp.new(@sub.sub.stat, @cfg[:hdb], @sv_stat)
        @shell_output_proc = proc { view.to_x }
        view.ext_log if @cfg[:option].log?
      end

      def ext_server
        @server_input_proc = proc do|line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = @shell_output_proc
        super
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
