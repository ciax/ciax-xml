#!/usr/bin/ruby
# Ascii Pack
require "libhexview"
require "libwatexe"

module CIAX
  module Hex
    def self.new(cfg)
      Hex::Sv.new(cfg)
    end

    class Sv < Exe
      def initialize(cfg)
        super
        wsh=Wat.new(@cfg)
        @cobj.svdom.replace wsh.cobj.svdom
        @mode=wsh.mode
        @output=View.new(@id,wsh.adb['version'],@cfg[:site_stat],wsh.stat)
        @post_exe_procs.concat(wsh.post_exe_procs)
        @server_input_proc=proc{|line|
          /^(strobe|stat)/ === line ? [] : line.split(' ')
        }
        @server_output_proc=proc{ @output.upd.to_x }
        @shell_output_proc=proc{ @output.upd.to_x }
        if $opt['e']
          @output.ext_log
        end
        ext_shell
        ext_server(wsh.adb['port'].to_i+1000) if ['e','s'].any?{|i| $opt[i]}
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
