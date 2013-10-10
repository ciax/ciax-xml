#!/usr/bin/ruby
require "libmsg"
require "libextcmd"

module CIAX
  module App
    class ExtCmd < Command
      def initialize(upper)
        super
        self['sv'].add('ext',ExtGrp)
        self['sv'].add('int',IntGrp)
      end
    end

    class IntGrp < Group
      def initialize(upper)
        super
        @cfg['caption']='Internal Commands'
        cri={:type => 'reg', :list => ['.']}
        add_item('set',{:label =>'[key=val,...]',:parameter =>[cri]})
        add_item('del',{:label =>'[key,...]',:parameter =>[cri]})
      end
    end

    class ExtGrp < ExtGrp
      def add(id,cls=ExtItem)
        super
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
      acf=Config.new
      acf[:db]=App::Db.new.set(app)
      fcf=Config.new
      fcf[:db]=Frm::Db.new.set(acf[:db]['frm_id'])
      fcobj=Frm::ExtCmd.new(fcf)
      acobj=App::ExtCmd.new(acf)
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
