#!/usr/bin/ruby
require "libextcmd"

module CIAX
  module App
    class Command < Command
      def initialize(upper)
        super
        @extgrp=self['sv'].add_group(:group_class =>ExtGrp,:item_class =>ExtItem)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
      end

      def add_int
        self['lo'].add_group(:group_class =>IntGrp)
      end
    end

    class IntGrp < Group
      def initialize(upper,crnt={})
        super
        @cfg['caption']='Test Commands'
        any={:type => 'reg', :list => ['.']}
        add_item('set',{:label =>'[key=val,...]',:parameter =>[any]})
        add_item('del',{:label =>'[key,...]',:parameter =>[any]})
      end
    end

    class ExtItem < Item
      #batch is ary of args(ary)
      def set_par(par)
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
      acf=Config.new
      acf[:db]=App::Db.new.set(app)
      fcf=Config.new
      fcf[:db]=Frm::Db.new.set(acf[:db]['frm_id'])
      fcobj=Frm::Command.new(fcf)
      acobj=App::Command.new(acf)
      acobj.setcmd(args).cfg[:batch].each{|fargs|
        #Validate batchs
        fcobj.setcmd(fargs) if /set|unset|load|save/ !~ fargs.first
        p fargs
      }
    rescue InvalidID
      Msg.usage("[app] [cmd] (par)")
    end
  end
end
