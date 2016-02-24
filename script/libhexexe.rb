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
        _init_prompt
        view = Rsp.new(@sub.sub.stat, @cfg)
        @cobj.add_rem(@sub.cobj.rem)
        @mode = @sub.mode
        @post_exe_procs.concat(@sub.post_exe_procs)
        @port = @sub.sub.port.to_i + 1000
        view.ext_log if @cfg[:option].log?
        @shell_output_proc = proc { view.to_x }
      end

      private

      def ext_server
        @server_input_proc = proc do|line|
          /^(strobe|stat)/ =~ line ? [] : line.split(' ')
        end
        @server_output_proc = @shell_output_proc
        super
      end
    end

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new('ceh:lts')
      id = ARGV.shift
      cfg = Config.new(option: opt)
      atrb = { hdb: Db.new, sub_list: Wat::List.new(cfg) }
      begin
        Exe.new(id, cfg, atrb).ext_shell.shell
      rescue InvalidID
        opt.usage('(opt) [id]')
      end
    end
  end
end
