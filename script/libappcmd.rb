#!/usr/bin/ruby
require "libmsg"
require "libextcmd"

module CIAX
  module App
    class ExtCmd < Command
      def initialize(db)
        super()
        sv=self['sv']
        sv['ext']=ExtGrp.new(db,sv.procs){|id,dprcs,gprcs|
          ExtItem.new(db,id,dprcs,gprcs)
        }
      end
    end

    class ExtItem < ExtItem
      #frmcmd is ary of ary
      def getcmd
        frmcmd=[]
        @select.each{|e1|
          cmd=[]
          enclose("AppItem","GetCmd(FDB):#{e1.first}","Exec(FDB):%s"){
            e1.each{|e2| # //argv
              case e2
              when String
                cmd << e2
              when Hash
                str=e2['val']
                str = e2['format'] % str if e2['format']
                verbose("AppItem","Calculated [#{str}]")
                cmd << str
              end
            }
            frmcmd.push cmd
            cmd
          }
        }
        frmcmd
      end
    end
  end

  if __FILE__ == $0
    require "libappdb"
    require "libfrmdb"
    require "libfrmcmd"
    app,*cmd=ARGV
    begin
      adb=App::Db.new.set(app)
      fdb=Frm::Db.new.set(adb['frm_id'])
      fcobj=Frm::ExtCmd.new(fdb)
      acobj=App::ExtCmd.new(adb)
      acobj.setcmd(cmd).getcmd.each{|fcmd|
        #Validate frmcmds
        fcobj.setcmd(fcmd) if /set|unset|load|save/ !~ fcmd.first
        p fcmd
      }
    rescue InvalidID
      Msg.usage("[app] [cmd] (par)")
    end
  end
end
