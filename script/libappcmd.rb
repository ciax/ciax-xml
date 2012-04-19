#!/usr/bin/ruby
require "libmsg"
require "libcommand"

class AppCmd
  include Math
  def initialize(cobj)
    @v=Msg::Ver.new(self,9)
    @cobj=Msg.type?(cobj,Command)
  end

  #frmcmd is ary of ary
  def get
    frmcmd=[]
    @cobj[:select].each{|e1|
      cmd=[]
      @v.msg(1){"GetCmd(FDB):#{e1.first}"}
      begin
        e1.each{|e2| # //argv
          case e2
          when String
            cmd << e2
          when Hash
            str=e2['val']
            str = e2['format'] % str if e2['format']
            @v.msg{"Calculated [#{str}]"}
            cmd << str
          end
        }
        frmcmd.push cmd
      ensure
        @v.msg(-1){"Exec(FDB):#{cmd}"}
      end
    }
    frmcmd
  end
end

if __FILE__ == $0
  require "libappdb"
  app,*cmd=ARGV
  begin
    adb=AppDb.new(app)
    fcobj=Command.new(adb.cover_frm[:cmdframe])
    acobj=Command.new(adb[:command]).set(cmd)
    AppCmd.new(acobj).get.each{|fcmd|
      fcobj.set(fcmd) if /set|unset|load|save|sleep/ !~ fcmd.first
      p fcmd
    }
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    Msg.usage("[app] [cmd] (par)")
  end
end
