#!/usr/bin/ruby
require "libextcmd"

module CIAX
  module App
    class Command < Command
      attr_reader :extgrp
      def initialize(upper)
        upper[:cls_color]=2
        super
        @extgrp=@svdom.add_group(:mod => Ext)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
        self
      end

      def add_int
        @svdom.add_group(:mod => Int)
        self
      end

      def set_dmy
        ext_proc{|ent|
          @cfg[:stat].upd
          'ISSUED:'+ent.batch.inspect
        }
        item_proc('interrupt'){|ent|
          "INTERRUPT(#{@cfg[:batch_interrupt]})"
        }
        self
      end
    end

    module Int
      class Group < Group
        def initialize(upper,crnt={})
          crnt[:group_id]='internal'
          super
          @cfg['caption']='Test Commands'
          any={:type => 'reg', :list => ['.']}
          add_item('set','[key] [val]',{:parameters =>[any,any]}).set_proc{|ent|
            @cfg[:stat].set(ent.par[0],ent.par[1])
            "SET:#{ent.par[0]}=#{ent.par[1]}"
          }
          add_item('del','[key,...]',{:parameters =>[any]}).set_proc{|ent|
            ent.par[0].split(',').each{|key| @cfg[:stat].del(key) }
            "DELETE:#{ent.par[0]}"
          }
        end
      end
    end

    module Ext
      include CIAX::Ext
      class Item < Item
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
                  str = e2['format'] % str if e2['format']
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

      class Entity < Entity
        attr_accessor :batch
      end
    end

    if __FILE__ == $0
      require "libappdb"
      require "libfrmdb"
      require "libfrmcmd"
      app,*args=ARGV
      begin
        acf=Config.new('app_test_cmd')
        acf[:db]=Db.new.set(app)
        acobj=Command.new(acf)
        acobj.set_cmd(args).batch.each{|fargs|
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
