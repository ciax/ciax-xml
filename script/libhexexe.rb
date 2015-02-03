#!/usr/bin/ruby
# Ascii Pack
require "libhexview"
require "libwatexe"

module CIAX
  module Hex
    # cfg should have [:wat_list](Wat::List)
    def self.new(wsh)
      Hex::Sv.new(wsh)
    end

    class Sv < Exe
      def initialize(cfg)
        wsh=Wat.new(cfg)
        super(wsh.id,cfg)
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
      ENV['VER']||='initialize'
      GetOpts.new('t')
      begin
        cfg=Config.new('hex')
        cfg[:db]=App::Db.new.set(ARGV.shift)
        puts Hex.new(cfg).shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
