#!/usr/bin/ruby
# Ascii Pack
require 'libwatlist'
require 'libhexview'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    # cfg must have [:db], [:sub_list]
    class Exe < Exe
      def initialize(id, cfg)
        super(id, cfg)
        @sub = @cfg[:sub_list].get(id).sub
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @sv_stat = @sub.sv_stat
        @post_exe_procs.concat(@sub.post_exe_procs)
        @port = @sub.port.to_i + 1000
        view = View.new(@sub.stat, @sv_stat)
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
      cfg = Config.new
      cfg[:jump_groups] = []
      cfg[:db] = Ins::Db.new
      cfg[:sub_list] = Wat::List.new(cfg)
      begin
        Exe.new(ARGV.shift, cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
