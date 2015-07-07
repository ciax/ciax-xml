#!/usr/bin/ruby
require "libremote"
require "libmcrdb"

module CIAX
  module Mcr
    include Remote
    class Index < Index
      def add_rem
        @cfg[:depth]=1
        super
      end
    end

    class Domain < Domain;end

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
          @valid_keys.clear
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
          depth=@cfg[:depth]
          @body.each{|elem|
            elem["depth"]=depth
            batch << elem
            next if elem["type"] != "mcr" || /true|1/ === elem["async"]
            grp=@cfg.ancestor(2)
            sub_batch=grp.set_cmd(elem["args"],{:depth => depth+1}).cfg[:batch]
            batch.concat sub_batch
          }
          @cfg[:batch]=batch
        end
      end
    end

    if __FILE__ == $0
      GetOpts.new
      proj=ENV['PROJ']||'ciax'
      cfg=Config.new
      cobj=Index.new(cfg)
      cobj.add_rem
      cobj.rem.proc{|ent| ent.cfg.path }
      cobj.rem.add_ext(Db.new.get(proj))
      begin
        ent=cobj.set_cmd(ARGV)
        puts ent.cfg[:batch].to_s
      rescue InvalidCMD
        $opt.usage("[id] [cmd] (par)")
      end
    end
  end
end
