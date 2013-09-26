#!/usr/bin/ruby
require "libmsg"
require "libextcmd"

module CIAX
  module App
    class ExtCmd < Command
      def initialize(db)
        super()
        sv=self['sv']
        sv['ext']=ExtGrp.new(db,[sv.set]){|id,pa|
          ExtItem.new(db,id,pa)
        }
      end
    end

    class ExtItem < ExtItem
      #fcmdary is ary of args(ary)
      def set_par(par)
        ent=super
        fcmdary=[]
        @select.each{|e1|
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
        ent.set[:cmdary]=fcmdary
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
      acobj.setcmd(args).get[:cmdary].each{|fargs|
        #Validate fcmdarys
        fcobj.setcmd(fargs) if /set|unset|load|save/ !~ fargs.first
        p fargs
      }
    rescue InvalidID
      Msg.usage("[app] [cmd] (par)")
    end
  end
end
