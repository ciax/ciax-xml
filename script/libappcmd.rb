#!/usr/bin/ruby
require "libmsg"
require "libcommand"
require "libbuffer"

module App
  module Cmd
    extend Msg::Ver
    def self.extended(obj)
      init_ver('AppCmd',9)
      Msg.type?(obj,Command)
    end

    #frmcmd is ary of ary
    def get
      frmcmd=[]
      self[:select].each{|e1|
        cmd=[]
        Cmd.msg(1){"GetCmd(FDB):#{e1.first}"}
        begin
          e1.each{|e2| # //argv
            case e2
            when String
              cmd << e2
            when Hash
              str=e2['val']
              str = e2['format'] % str if e2['format']
              Cmd.msg{"Calculated [#{str}]"}
              cmd << str
            end
          }
          frmcmd.push cmd
        ensure
          Cmd.msg(-1){"Exec(FDB):#{cmd}"}
        end
      }
      frmcmd
    end
  end

  module Exe
    attr_reader :buf
    def self.extended(obj)
      Msg.type?(obj,Cmd).extend(Command::Exe).init
    end

    def init
      @buf=Buffer.new
      def_proc{|pri|
          @buf.send(pri){ get }
          "IssueD"
        }
    end
  end
end

if __FILE__ == $0
  require "libappdb"
  app,*cmd=ARGV
  begin
    adb=App::Db.new(app)
    fcobj=Command.new(adb.cover_frm[:cmdframe])
    acobj=Command.new(adb[:command]).set(cmd)
    acobj.extend(App::Cmd).get.each{|fcmd|
      fcobj.set(fcmd) if /set|unset|load|save|sleep/ !~ fcmd.first
      p fcmd
    }
  rescue UserError
    Msg.usage("[app] [cmd] (par)")
  end
end
