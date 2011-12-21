#!/usr/bin/ruby
require "libmsg"
require "libcommand"

class AppCmd < Command
  include Math
  def initialize(db)
    super
    @v=Msg::Ver.new(self,9)
  end

  def get
    frmcmd=[]
    self[:select].each{|e1|
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
    fp=Command.new(adb.cover_frm[:cmdframe])
    AppCmd.new(adb[:command]).set(cmd).get.each{|fcmd|
      fp.set(fcmd) if /set|unset|load|save|sleep/ !~ fcmd.first
      p fcmd
    }
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    Msg.usage("[app] [cmd] (par)")
  end
end
