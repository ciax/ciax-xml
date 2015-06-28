#!/usr/bin/ruby
# Ascii Pack
require "libwatexe"
require "libhexview"

module CIAX
  $layers['x']=Hex
  module Hex
    include Command

    def self.new(id,cfg={},attr={})
      Hex::Sv.new(id,cfg,attr)
    end

    # cfg should have [:layers]
    class Sv < Exe
      def initialize(id,cfg={},attr={})
        super
        ash=@cfg[:sub_list].get(id).ash
        @cobj=Index.new(@cfg)
        @cobj.add_rem(ash)
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

    class Index < Wat::Index; end

    class List < Site::List
      def initialize(cfg,attr={})
        attr[:layer]=Hex
        sub=Wat::List.new(cfg)
        attr[:sub_list]=sub
        attr[:db]=sub.cfg[:db]
        super
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      cfg=Config.new
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
