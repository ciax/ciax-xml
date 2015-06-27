#!/usr/bin/ruby
# Ascii Pack
require "libhexview"
require "libwatlist"

module CIAX
  $layers['x']=Hex
  module Hex
    def self.new(id,cfg={},attr={})
      Hex::Sv.new(id,cfg,attr)
    end

    # cfg should have layer[:wat]
    class Sv < Exe
      def initialize(id,cfg={},attr={})
        super
        ash=@cfg.layers[:app].get(id)
        @cobj=ash.cobj
        @mode=ash.mode
        @output=View.new(@id,ash.adb['version'],ash.site_stat,ash.stat)
        @post_exe_procs.concat(ash.post_exe_procs)
        @server_input_proc=proc{|line|
          /^(strobe|stat)/ === line ? [] : line.split(' ')
        }
        @server_output_proc=proc{ @output.upd.to_x }
        @shell_output_proc=proc{ @output.upd.to_x }
        if $opt['e']
          @output.ext_log
        end
        ext_server(ash.port.to_i+1000) if ['e','s'].any?{|i| $opt[i]}
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celst')
      cfg=Config.new
      cfg[:jump_groups]=[]
      begin
        Frm::List.new(cfg)
        App::List.new(cfg)
        Wat::List.new(cfg)
        Sv.new(ARGV.shift,cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
