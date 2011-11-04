#!/usr/bin/ruby
require "libmsg"
require "libparam"

class AppCmd < Array
  include Math
  def initialize(par)
    @v=Msg::Ver.new("app/cmd",9)
    @par=Msg.type?(par,Param)
  end

  def getcmd
    clear
    @par[:select].each{|e1|
      cmd=[]
      @v.msg(1){"GetCmd(FDB):#{e1.first}"}
      begin
        e1.each{|e2| # //argv
          case e2
          when String
            cmd << e2
          when Hash
            str=e2['val']
            str = e2['format'] % eval(str) if e2['format']
            @v.msg{"Calculated [#{str}]"}
            cmd << str
          end
        }
        push cmd
      ensure
        @v.msg(-1){"Exec(FDB):#{cmd}"}
      end
    }
    self
  end
end

if __FILE__ == $0
  require "libappdb"
  app,*cmd=ARGV
  begin
    adb=AppDb.new(app,cmd.empty?)
    fp=Param.new(adb.cover_frm[:cmdframe])
    ap=Param.new(adb[:command]).set(cmd)
    AppCmd.new(ap).getcmd.each{|fcmd|
      fp.set(fcmd) if /set|unset|load|save/ !~ fcmd.first
      p fcmd
    }
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    warn "Usage: #{$0} [app] [cmd] (par)"
    Msg.exit
  end
end
