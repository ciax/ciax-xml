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
      def initialize(wsh)
        type?(wsh,Wat::Exe)
        super('hex',wsh.id)
        @cobj.svdom.replace wsh.cobj.svdom
        @site_stat=wsh.site_stat
        @mode=wsh.mode
        @output=View.new(@id,wsh.adb['version'],wsh,wsh.stat)
        @post_exe_procs.concat(wsh.post_exe_procs)
        @server_input_proc=proc{|line|
          /^(strobe|stat)/ === line ? [] : line.split(' ')
        }
        @server_output_proc=proc{ @output.to_x }
        @shell_output_proc=proc{ @output.to_x }
        if $opt['e']
          @output.ext_log
        end
        ext_shell
        ext_server(wsh.adb['port'].to_i+1000) if ['e','s'].any?{|i| $opt[i]}
      end
    end

    class List < Site::List
      def initialize(upper=nil)
        super(Hex,upper)
        @cfg[:level]='hex'
        @cfg.layers[:hex]=self
        Wat::List.new(@cfg)
      end

      def add(id)
        set(id,Hex.new(@cfg.layers[:wat].get(id)))
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
