#!/usr/bin/ruby
require "libinteract"
require "libstat"
require "libfrmlist"
module App
  class Int < Interact
    def initialize(adb)
      @adb=Msg.type?(adb,App::Db)
      super(Command.new(adb[:command]))
      @prompt['id']=adb['id']
      @port=adb['port'].to_i
      @stat=Stat.new
      @watch=Watch.new
      ic=@cmdlist['internal']
      ic['set']="[key=val], .."
      ic['flush']="Flush Status"
      tbl=@prompt.table
      tbl['auto']='@'
      tbl['watch']='&'
      tbl['isu']='*'
      tbl['na']='X'
      @fint=FrmList.new[adb['id']]
    end

    def shell
      cl=Msg::CmdList.new("Change Layer",2)
      cl.update({'frm' => "Frm mode",'app' => "App mode"})
      @fint.cmdlist['layer']=@cmdlist['layer']=cl
      id='app'
      loop{
        case id
        when 'app'
          id=super
        when 'frm'
          id=@fint.shell
        else
          break id
        end
      }
    end

    def to_s
      @stat.to_s
    end
  end
end
