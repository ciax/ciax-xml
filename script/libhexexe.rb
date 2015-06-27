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

    # cfg should have [:layers]
    class Sv < Exe
      def initialize(id,cfg={},attr={})
        super
        ash=@cfg[:layers].get('app').get(id)
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

    include Command
    class Index < GrpAry
      attr_reader :loc,:rem,:ash
      def initialize(cfg,attr={})
        super
        @cfg[:layer]||=Hex
        @cfg[:cls_color]=3
        @loc=add(Local::Domain)
      end

      def add_rem(ash)
        unshift @rem=ash.cobj.rem
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celst')
      cfg=Config.new
      cfg[:jump_groups]=[]
      sl=cfg[:layers]=Site::Layer.new(cfg)
      begin
        sl.add_layer(Frm)
        sl.add_layer(App)
        sl.add_layer(Wat)
        Sv.new(ARGV.shift,cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
