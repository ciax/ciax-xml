#!/usr/bin/ruby
# Ascii Pack
require "libwatexe"
require "libhexview"

module CIAX
  module Hex
    include Command

    def self.new(id,cfg,attr={})
      Hex::Sv.new(id,cfg,attr)
    end

    # cfg should have [:sub_list]
    class Sv < Exe
      def initialize(id,cfg,attr={})
        super
        sub=@cfg[:sub_list].get(id).sub
        @cobj=Index.new(@cfg)
        @cobj.add_rem(sub)
        @mode=sub.mode
        @cfg[:output]=View.new(sub.stat,sub.site_stat)
        @post_exe_procs.concat(sub.post_exe_procs)
        @cfg['port']=sub.cfg['port'].to_i+1000
        if $opt['e']
          @cfg[:output].ext_log
        end
      end

      def ext_shell
        super
        @shell_output_proc=proc{ @cfg[:output].upd.to_s }
        self
      end

      def ext_server
        @server_input_proc=proc{|line|
          /^(strobe|stat)/ === line ? [] : line.split(' ')
        }
        @server_output_proc=proc{ @cfg[:output].upd.to_s }
        super
      end
    end

    class Index < Wat::Index; end

    class List < Site::List
      def initialize(cfg,attr={})
        attr[:sub_list]=Wat::List.new(cfg)
        super
        set_db(Ins::Db.new) unless @cfg[:db]
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('ceh:lts')
      cfg=Config.new
      cfg[:site]=ARGV.shift
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
