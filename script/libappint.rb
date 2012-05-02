#!/usr/bin/ruby
require "libinteract"
require "libstat"
module App
  class Int < Interact
    def initialize(adb)
      @adb=Msg.type?(adb,App::Db)
      super(Command.new(adb[:command]))
      @prompt['id']=adb['id']
      @port=adb['port'].to_i
      @stat=Stat.new
      @watch=Watch.new
      ic=@cobj.list['internal']
      ic['set']="[key=val], .."
      ic['flush']="Flush Status"
      tbl=@prompt.table
      tbl['auto']='@'
      tbl['watch']='&'
      tbl['isu']='*'
      tbl['na']='X'
      @fint=nil
    end

    def shell(modes={})
      if @fint
        modes.update({'frm' => "Frm mode",'app' => "App mode"})
        id='app'
        loop{
          case id
          when 'app'
            id=super
          when 'frm'
            id=@fint.shell(modes)
          else
            break id
          end
        }
      else
        super
      end
    end

    def to_s
      @stat.to_s
    end
  end
end
