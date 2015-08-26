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
        attr_reader :par
        def initialize(cfg,crnt={})
          super
          @par={:type => 'str',:list => [],:default => '0'}
          @cfg[:parameters]=[@par]
          {
            "start"=>"Sequence",
            "exec"=>"Command",
            "skip"=>"Execution",
            "drop"=>" Macro",
            "suppress"=>"and Memorize",
            "force"=>"Proceed",
            "pass"=>"Step",
            "ok"=>"for the message",
            "retry"=>"Checking",
          }.each{|id,cap|
            add_item(id,id.capitalize+" "+cap)
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
          depth=@cfg[:depth]
          @body.each{|elem|
            elem["depth"]=depth
            case elem['type']
            when "mcr"
              batch << elem
              next if /true|1/ === elem["async"]
              batch.concat sub_batch(elem['args'])
            when "select"
              sel=elem['select']
              val=@cfg[:sub_list].getstat(elem)
              args=sel[val]||sel['*']
              @cfg['select']=args.join(':')
              batch.concat sub_batch(args)
            else
              batch << elem
            end
          }
          @cfg[:batch]=batch
        end

        private
        def sub_batch(args)
          grp=@cfg.ancestor(2)
          grp.set_cmd(args,{:depth => @cfg[:depth]+1}).cfg[:batch]
        end
      end
    end

    if __FILE__ == $0
      require "libwatexe"
      GetOpts.new
      cfg=Config.new
      cfg[:sub_list]=Wat::List.new(cfg)
      cobj=Index.new(cfg)
      cobj.add_rem
      cobj.rem.def_proc{|ent| ent.cfg.path }
      cobj.rem.add_ext(Db.new.get(PROJ))
      begin
        ent=cobj.set_cmd(ARGV)
        puts ent.cfg.path
        puts ent.cfg[:batch].to_v
      rescue InvalidCMD
        $opt.usage("[id] [cmd] (par)")
      end
    end
  end
end
