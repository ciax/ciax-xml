#!/usr/bin/ruby
# Ascii Pack
require "libhexview"
require "libwatexe"

module CIAX
  module Hex
    def self.new(site_cfg,attr={})
      Hex::Sv.new(site_cfg,attr)
    end

    class Sv < Exe
      def initialize(site_cfg,attr={})
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
        ext_shell
        ext_server(ash.port.to_i+1000) if ['e','s'].any?{|i| $opt[i]}
      end
    end

    if __FILE__ == $0
      require "libsitedb"
      ENV['VER']||='initialize'
      GetOpts.new('celst')
      id=ARGV.shift
      begin
        cfg=Site::Db.new.set(id)
        puts Hex.new(cfg).shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
