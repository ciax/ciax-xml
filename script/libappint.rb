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
      @prompt.table.update({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
      @fint=FrmList.new[adb['id']]
    end

    def exe(cmd)
      super
    rescue SelectCMD
      cl=Msg::CmdList.new("Internal Command",2)
      cl['set']="[key=val], .."
      cl['flush']="Flush Status"
      cl.error
    end


    def shell
      cl=Msg::CmdList.new("Change Layer",2)
      cl.update({'frm' => "Frm mode",'app' => "App mode"})
      id='app'
      default=id
      estr=''
      loop{
        case id
        when 'app'
          default=id
          id,estr=super || break
        when 'frm'
          default=id
          id,estr=@fint.shell || break
        else
          id=default
          estr+="\n"+cl.to_s
          puts estr
        end
      }
    end

    def to_s
      @stat.to_s
    end
  end
end
