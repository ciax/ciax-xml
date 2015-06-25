#!/usr/bin/ruby
require "liblocal"
require "libremote"

module CIAX
  module App
    include Command
    class Index < GrpAry
      attr_reader :loc,:rem
      def initialize(cfg,attr={})
        super
        @cfg[:cls_color]=3
        @loc=add(Local::Domain)
        @rem=add(Domain)
      end
    end

    class Domain < Remote::Domain
      attr_reader :ext,:int
      def initialize(cfg,attr={})
        super
        @ext=add(Ext::Group)
      end

      def add_int
        @int=add(Int::Group)
      end
    end

    module Int
      include Remote::Int
      class Group < Group
        def initialize(cfg,attr={})
          super
          add_item('set','[key] [val]',def_pars(2)).cfg.proc{|ent|
            @cfg[:stat].put(ent.par[0],ent.par[1])
            "SET:#{ent.par[0]}=#{ent.par[1]}"
          }
          add_item('del','[key,...]',def_pars(1)).cfg.proc{|ent|
            ent.par[0].split(',').each{|key| @cfg[:stat].del(key) }
            "DELETE:#{ent.par[0]}"
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
      class Entity < Entity
        include Math
        #batch is ary of args(ary)
        def initialize(cfg,attr={})
          super
          @cfg[:batch]=@body.map{|e1|
            args=[]
            enclose("AppItem","GetCmd(FDB):#{e1.first}","Exec(FDB):%s"){
              e1.each{|e2| # //argv
                case e2
                when String
                  args << e2
                when Hash
                  str=e2['val']
                  str = e2['format'] % eval(str) if e2['format']
                  verbose("AppItem","Calculated [#{str}]")
                  args << str
                end
              }
            }
            args
          }.extend(Enumx)
        end
      end
    end

    if __FILE__ == $0
      require "libappdb"
      app,*args=ARGV
      begin
        cfg=Config.new('test',{:dbi => Db.new.get(app)})
        cobj=Index.new(cfg)
        cobj.rem.ext.cfg.proc{|ent| ent.cfg.path }
        ent=cobj.set_cmd(args)
        puts ent.exe_cmd('test')
        puts ent.cfg[:batch].to_s
      rescue InvalidCMD
        Msg.usage("#{app} [cmd] (par)",2)
      rescue InvalidID
        Msg.usage("[app] [cmd] (par)")
      end
    end
  end
end
