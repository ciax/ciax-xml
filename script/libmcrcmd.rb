#!/usr/bin/ruby
require "libremote"

module CIAX
  module Mcr
    class Command < Command
      attr_reader :rem
      def initialize(cfg,attr={})
        super
        @cfg[:depth]=1
        @cfg[:mobj]=self
        @rem=add(Domain)
      end
    end

    class Domain < Remote::Domain
      attr_reader :ext,:int
      def initialize(cfg,attr={})
        super
        @ext=add(Ext::Index,{:group_id => 'external'})
      end

      def add_int
        @int=add(Int::Index,{:group_id => 'internal'})
      end
    end

    module Int
      include Remote::Int
      class Index < Index
        attr_reader :valid_pars
        def initialize(cfg,crnt={})
          super
          @valid_pars=[]
          parlist={:parameters => [{:type => 'str',:list => @valid_pars,:default => nil}]}
          @cfg['caption']='Internal Commands'
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
      class Index < Index;end
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
            batch.concat @cfg[:mobj].set_cmd(elem["args"],{:depth => @cfg[:depth]+1}).cfg[:body]
          }
          @cfg[:batch]=batch
        end
      end
    end

    if __FILE__ == $0
      require "libmcrdb"
      GetOpts.new
      begin
        cfg=Config.new('test',{:db => Db.new.get(ENV['PROJ']||'ciax')})
        cobj=Command.new(cfg)
        cobj.rem.ext.cfg.proc{|ent| ent.cfg.path }
        ent=cobj.set_cmd(ARGV)
        puts ent.exe_cmd('test')
        puts ent.cfg[:batch].to_s
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
