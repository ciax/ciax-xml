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
        @sub = cfg[:sub_list].get(id).sub
        @sv_stat = @sub.sv_stat
        view = Rsp.new(cfg[:db], @sub.stat, @sv_stat)
        super
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @post_exe_procs.concat(@sub.post_exe_procs)
        @port = @sub.port.to_i + 1000
        view.ext_log if OPT[:e]
        @shell_output_proc = proc { view.to_x }
      end

      def ext_server
        super
        @server_input_proc = proc do|line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = @shell_output_proc
        self
      end
    end

    # Hex Exe List
    class List < Site::List
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self, Wat::List)
        store_db(@sub_list.db)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('ceh:lts')
      id =ARGV.shift
      cfg = Config.new
      cfg[:sub_list] = Wat::List.new(cfg)
      cfg[:db] = Db.new
      begin
        Exe.new(id, cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
