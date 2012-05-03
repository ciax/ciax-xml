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
      int={'set'=>"[key=val], ..",'flush'=>"Flush Status"}
      @cmdlist.add_group('int',"Internal Command",int,2)
      @cmdlist.add_group('lay',"Change Layer",{'frm'=>"Frm mode"},2)
      @fint.cmdlist.add_group('lay',"Change Layer",{'app'=>"App mode"},2)
    end

    def shell
      id='app'
      loop{
        case id
        when /app/
          id=super||break
        when /frm/
          id=@fint.shell||break
        else
          return id
        end
      }
    end

    def to_s
      @stat.to_s
    end
  end
end
