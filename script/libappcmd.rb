#!/usr/bin/ruby
require "libmsg"
require "libextcmd"

module CIAX
  module App
    class ExtCmd < ExtCmd
      def initialize(db)
        super
        add_svgrp('ext',ExtGrp)
      end
    end

    class IntGrp < Group
      def initialize(upper)
        super
        @cfg['caption']='Internal Commands'
        cri={:type => 'reg', :list => ['.']}
        add_item('set','[key=val,...]',[cri])
        add_item('del','[key,...]',[cri])
      end
    end

    class ExtGrp < ExtGrp
      def new_item(crnt)
        ExtItem.new(@cfg,crnt)
      end
    end

    class ExtItem < ExtItem
      #fcmdary is ary of args(ary)
      def set_par(par)
        ent=super
        fcmdary=[]
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
            fcmdary.push args
            args
          }
        }
        ent.cfg[:cmdary]=fcmdary
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
      adb=App::Db.new.set(app)
      fdb=Frm::Db.new.set(adb['frm_id'])
      fcobj=Frm::ExtCmd.new(fdb)
      acobj=App::ExtCmd.new(adb)
      acobj.setcmd(args).cfg[:cmdary].each{|fargs|
        #Validate fcmdarys
        fcobj.setcmd(fargs) if /set|unset|load|save/ !~ fargs.first
        p fargs
      }
    rescue InvalidID
      Msg.usage("[app] [cmd] (par)")
    end
  end
end
