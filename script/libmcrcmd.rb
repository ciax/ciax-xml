#!/usr/bin/ruby
require "liblocal"
require "libremote"
require "libmcrdb"

module CIAX
  module Mcr
    include Command
    class Index < GrpAry
      # cfg should have [:dbi]
      attr_reader :loc,:rem
      def initialize(cfg,attr={})
        super
        @cfg[:layer]=Mcr
        @cfg[:depth]=1
        @cfg[:mobj]=self
        @loc=add(Local::Domain)
        @rem=add(Remote::Domain)
      end
    end

    module Int
      include Remote::Int
      class Group < Group
        attr_reader :valid_pars
        def initialize(cfg,crnt={})
          super
          @valid_pars=[]
          parlist={:parameters => [{:type => 'str',:list => @valid_pars,:default => nil}]}
          {
            "exec"=>"Command",
            "skip"=>"Execution",
            "drop"=>" Macro",
            "suppress"=>"and Memorize",
            "force"=>"Proceed",
            "pass"=>"Step",
            "ok"=>"for the message",
            "retry"=>"Checking",
          }.each{|id,cap|
            add_item(id,id.capitalize+" "+cap,parlist)
          }
        end
      end
      class Item < Item;end
      class Entity < Entity;end
    end

    module Ext
      include Remote::Ext
      class Group < Group;end
      class Item < Item;end
      class Entity < Ext::Entity
        attr_reader :batch
        def initialize(cfg,crnt={})
          super
          # @cfg[:body] expansion
          batch=Arrayx.new
          @body.each{|elem|
            elem["depth"]=@cfg[:depth]
            batch << elem
            next if elem["type"] != "mcr" || /true|1/ === elem["async"]
            batch.concat @cfg[:mobj].set_cmd(elem["args"],{:depth => @cfg[:depth]+1}).cfg[:batch]
          }
          @cfg[:batch]=batch
        end
      end
    end

    if __FILE__ == $0
      GetOpts.new
      proj=ENV['PROJ']||'ciax'
      begin
        cfg=Config.new
        cfg[:dbi]=Db.new.get(proj)
        cobj=Index.new(cfg)
        cobj.rem.ext.proc{|ent| ent.cfg.path }
        ent=cobj.set_cmd(ARGV)
        puts ent.exe_cmd('test')
        puts ent.cfg[:batch].to_s
      rescue InvalidCMD
        $opt.usage("[id] [cmd] (par)")
      end
    end
  end
end
