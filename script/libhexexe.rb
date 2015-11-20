#!/usr/bin/ruby
# Ascii Pack
require 'libwatexe'
require 'libhexview'

module CIAX
  module Hex
    # cfg should have [:sub_list]
    class Exe < Exe
      def initialize(id, cfg)
        super(id, cfg)
        @sub = @cfg[:sub_list].get(id).sub
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @cfg[:output] = View.new(@sub.stat, @sub.sv_stat)
        @post_exe_procs.concat(@sub.post_exe_procs)
        @port = @sub.port.to_i + 1000
        @cfg[:output].ext_log if OPT[:e]
      end

      def ext_server
        super
        @server_input_proc = proc do|line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = proc { @cfg[:output].to_s }
        self
      end
    end

    class List < Site::List
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self, Wat::List)
        store_db(@sub_list.db)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('ceh:lts')
      cfg = Config.new
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
