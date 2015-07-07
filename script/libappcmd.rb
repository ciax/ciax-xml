#!/usr/bin/ruby
require "liblocal"
require "libremote"
require "libappdb"

module CIAX
  module App
    include Remote
    class Index < GrpAry
      # cfg should have [:dbi] and [:stat]
      attr_reader :loc,:rem
      def initialize(cfg,attr={})
        super
        @loc=add(Local::Domain)
        @rem=add(Domain)
      end
    end

    class Domain < Domain;end

    module Int
      include Remote::Int
      class Group < Group
        def initialize(cfg,attr={})
          super
          add_item('set','[key] [val]',def_pars(2)).proc{|ent|
            @cfg[:stat].put(ent.par[0],ent.par[1])
            "SET:#{ent.par[0]}=#{ent.par[1]}"
          }
          add_item('del','[key,...]',def_pars(1)).proc{|ent|
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
            enclose("GetCmd(FDB):#{e1.first}","Exec(FDB):%s"){
              e1.each{|e2| # //argv
                case e2
                when String
                  args << e2
                when Hash
                  str=e2['val']
                  str = e2['format'] % eval(str) if e2['format']
                  verbose("Calculated [#{str}]")
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
      GetOpts.new
      id=ARGV.shift
      cfg=Config.new
      cobj=Index.new(cfg)
      cobj.rem.proc{|ent| ent.cfg.path }
      begin
        cobj.rem.add_ext(Db.new.get(id))
        ent=cobj.set_cmd(ARGV)
        puts ent.exe_cmd('test')
        puts ent.cfg[:batch].to_s
      rescue InvalidCMD
        Msg.usage("#{id} [cmd] (par)",2)
      rescue InvalidID
        Msg.usage("[id] [cmd] (par)")
      end
    end
  end
end
