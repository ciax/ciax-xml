#!/usr/bin/ruby
require "libextcmd"

module CIAX
  module App
    class Command < Command
      attr_reader :extgrp
      def initialize(upper)
        super
        @extgrp=@svdom.add_group(:group_class =>ExtGrp,:item_class =>ExtItem)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
        self
      end

      def add_int
        @svdom.add_group(:group_class =>IntGrp)
        self
      end
    end

    class IntGrp < Group
      def initialize(upper,crnt={})
        crnt[:group_id]='internal'
        super
        @cfg['caption']='Test Commands'
        any={:type => 'reg', :list => ['.']}
        add_item('set','[key] [val]',{:parameters =>[any,any]})
        add_item('del','[key,...]',{:parameters =>[any]})
      end
    end

    class ExtItem < Item
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
        ent.cfg[:batch]=batch
        ent
      end
    end
  end

  if __FILE__ == $0
    require "libappdb"
    require "libfrmdb"
    require "libfrmcmd"
    app,*args=ARGV
    begin
      acf=Config.new('app_top')
      acf[:db]=App::Db.new.set(app)
      acobj=App::Command.new(acf)
      acobj.set_cmd(args).cfg[:batch].each{|fargs|
        p fargs
      }
    rescue InvalidCMD
      Msg.usage("#{app} [cmd] (par)",2)
    rescue InvalidID
      Msg.usage("[app] [cmd] (par)")
    end
  end
end
