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
      class Group < Int::Group
        attr_reader :par
        def initialize(cfg,crnt={})
          super
          @par={:type => 'str',:list => [],:default => '0'}
          @cfg[:parameters]=[@par]
          {
            "start"=>"Sequence",
            "exec"=>"Command",
            "skip"=>"Macro",
            "drop"=>" Macro",
            "suppress"=>"and Memorize",
            "force"=>"Proceed",
            "pass"=>"Execution",
            "ok"=>"for the message",
            "retry"=>"Checking",
          }.each{|id,cap|
            add_item(id,id.capitalize+" "+cap)
          }
        end
      end
      class Item < Int::Item;end
      class Entity < Int::Entity;end
    end

    module Ext
      include Remote::Ext
      class Group < Ext::Group;end
      class Item < Ext::Item;end
      class Entity < Ext::Entity
        attr_reader :sequence
        def initialize(cfg,crnt={})
          super
          # @cfg[:body] expansion
          sequence=Arrayx.new
          depth=@cfg[:depth]
          @body.each{|elem|
            case elem['type']
            when "select"
              hash={'type' => 'mcr'}
              sel=elem['select']
              val=@cfg[:sub_list].getstat(elem)
              hash['args']=sel[val]||sel['*']
              sequence << hash
            else
              sequence << elem
            end
          }
          @sequence=@cfg[:sequence]=sequence
        end

        private
        def sub_sequence(args,depth)
          grp=@cfg.ancestor(2)
          grp.set_cmd(args,{:depth => depth}).cfg[:sequence]
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
        puts ent.sequence.to_v
      rescue InvalidCMD
        $opt.usage("[id] [cmd] (par)")
      end
    end
  end
end
