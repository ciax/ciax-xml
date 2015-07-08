#!/usr/bin/ruby
# Ascii Pack
require "libwatexe"
require "libhexview"

module CIAX
  module Hex
    include Command

    def self.new(id,cfg={},attr={})
      Hex::Sv.new(id,cfg,attr)
    end

    # cfg should have [:layers]
    class Sv < Exe
      def initialize(id,cfg={},attr={})
        super
        sub=@cfg[:sub_list].get(id).sub
        @cobj=Index.new(@cfg)
        @cobj.add_rem(sub)
        @cobj.rem.add_hid
        @mode=sub.mode
        @output=View.new(@id,sub.cfg['ver'],sub.site_stat,sub.stat)
        @post_exe_procs.concat(sub.post_exe_procs)
        @cfg['port']=sub.cfg['port'].to_i+1000
        if $opt['e']
          @output.ext_log
        end
      end

      def ext_shell
        @shell_output_proc=proc{ @output.upd.to_x }
        super
      end

      def ext_server
        @server_input_proc=proc{|line|
          /^(strobe|stat)/ === line ? [] : line.split(' ')
        }
        @server_output_proc=proc{ @output.upd.to_x }
        super
      end
    end

    class Index < Wat::Index; end

    class List < Site::List
      def initialize(cfg,attr={})
        super
        set_db(Ins::Db.new) unless @cfg[:db]
        @cfg[:sub_list]=sub_list(Wat)
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      cfg=Config.new
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
