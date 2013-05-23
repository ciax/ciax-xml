#!/usr/bin/ruby
require "libmsg"
require "libcmdext"

module App
  class ExtGrp < Command::ExtGrp
    def initialize(db)
      @db=Msg.type?(db,Db)
      @valid_keys=[]
      @cmdlist=[]
      @def_proc=ExeProc.new
      if @cdb=db[:command]
        gdb=@cdb[:group]
        gdb.each{|gid,gat|
          subgrp=Msg::CmdList.new(gat,@valid_keys)
          gat[:members].each{|id|
            subgrp[id]=@cdb[:label][id]
            self[id]=ExtItem.new(@cdb,id,@def_proc)
          }
          @cmdlist << subgrp
        }
        @cdb[:alias].each{|k,v| self[k].replace self[v]} if @cdb.key?(:alias)
      end
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
    fsvdom=fcobj.add_domain('sv')
    fsvdom['ext']=Frm::ExtGrp.new(Frm::Db.new.set(adb['frm_id']))
    acobj=Command.new
    asvdom=acobj.add_domain('sv')
    asvdom['ext']=App::ExtGrp.new(adb)
    acobj.setcmd(cmd).getcmd.each{|fcmd|
      #Validate frmcmds
      fcobj.setcmd(fcmd) if /set|unset|load|save/ !~ fcmd.first
      p fcmd
    }
  rescue InvalidID
    Msg.usage("[app] [cmd] (par)")
  end
end
