#!/usr/bin/ruby
require "libmsg"
require "libcmdext"

module App
  class ExtGrp < Command::ExtGrp
    private
    def extitem(id)
      ExtItem.new(@db,id,@def_proc)
    end
  end

  class ExtItem < Command::ExtItem
    #frmcmd is ary of ary
    def getcmd
      frmcmd=[]
      @select.each{|e1|
        cmd=[]
        verbose(1){"GetCmd(FDB):#{e1.first}"}
        begin
          e1.each{|e2| # //argv
            case e2
            when String
              cmd << e2
            when Hash
              str=e2['val']
              str = e2['format'] % str if e2['format']
              verbose{"Calculated [#{str}]"}
              cmd << str
            end
          }
          frmcmd.push cmd
        ensure
          verbose(-1){"Exec(FDB):#{cmd}"}
        end
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
    fcobj=Command.new
    fcobj['sv']['ext']=Frm::ExtGrp.new(Frm::Db.new.set(adb['frm_id']))
    acobj=Command.new
    acobj['sv']['ext']=App::ExtGrp.new(adb)
    acobj.setcmd(cmd).getcmd.each{|fcmd|
      #Validate frmcmds
      fcobj.setcmd(fcmd) if /set|unset|load|save/ !~ fcmd.first
      p fcmd
    }
  rescue InvalidID
    Msg.usage("[app] [cmd] (par)")
  end
end
