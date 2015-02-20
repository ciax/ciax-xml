#!/usr/bin/ruby
# Ascii Pack
require "libhexview"
require "libwatexe"

module CIAX
  $layers['hex']=Hex
  module Hex
    def self.new(site_cfg,layer_cfg={})
      Hex::Sv.new(site_cfg,layer_cfg)
    end

    class Sv < Exe
      def initialize(site_cfg,layer_cfg={})
        super
        ash=Wat.new(@cfg).ash
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

    class List < Site::List
      def initialize
        super('hex')
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celst')
      id=ARGV.shift
      begin
        Sv.new('id'=>id).ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
