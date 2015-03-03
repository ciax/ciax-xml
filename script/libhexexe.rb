#!/usr/bin/ruby
# Ascii Pack
require "libhexview"
require "libwatlist"

module CIAX
  $layers['x']=Hex
  module Hex
    def self.new(id,site_cfg={},hex_cfg={})
      Hex::Sv.new(id,site_cfg,hex_cfg)
    end

    class Sv < Exe
      def initialize(id,site_cfg={},hex_cfg={})
        super
        ash=Wat.new(id,@cfg).ash
        @cobj.svdom.replace ash.cobj.svdom
        @mode=ash.mode
        @output=View.new(@id,ash.adb['version'],@cfg[:site_stat],ash.stat)
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
      cfg=Config.new('test',{:site_stat => Prompt.new})
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
