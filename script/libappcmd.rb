#!/usr/bin/ruby
require "libextcmd"

module CIAX
  module App
    class Command < Command
      # exe_cfg or attr should have [:db]
      def initialize(exe_cfg,attr={})
        attr[:cls_color]=3
        super
        add_extgrp(Ext)
      end
    end

    module Int
      class Group < CIAX::Int::Group
        def initialize(dom_cfg,attr={})
          super
          @cfg['caption']='Test Commands'
          add_item('set','[key] [val]',def_pars(2)).set_proc{|ent|
            @cfg[:stat].put(ent.par[0],ent.par[1])
            "SET:#{ent.par[0]}=#{ent.par[1]}"
          }
          add_item('del','[key,...]',def_pars(1)).set_proc{|ent|
            ent.par[0].split(',').each{|key| @cfg[:stat].del(key) }
            "DELETE:#{ent.par[0]}"
          }
        end
      end
    end

    module Ext
      include CIAX::Ext
      class Item < Item
        include Math
        #batch is ary of args(ary)
        def set_par(par,opt={})
          ent=super
          batch=[]
          ent.cfg[:body].each{|e1|
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
              batch.push args
              args
            }
          }
          ent.batch=batch
          ent
        end
      end

      class Entity < CIAX::Ext::Entity
        attr_accessor :batch
      end
    end

    if __FILE__ == $0
      require "libappdb"
      app,*args=ARGV
      begin
        cobj=Command.new(:db => Db.new.get(app))
        cobj.set_cmd(args).batch.each{|fargs|
          p fargs
        }
      rescue InvalidCMD
        Msg.usage("#{app} [cmd] (par)",2)
      rescue InvalidID
        Msg.usage("[app] [cmd] (par)")
      end
    end
  end
end
