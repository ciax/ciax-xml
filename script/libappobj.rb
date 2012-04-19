#!/usr/bin/ruby
require "libinteract"
require "libstat"
class AppObj < Interact
  def initialize(adb)
    @adb=Msg.type?(adb,AppDb)
    super(Command.new(adb[:command]))
    @prompt['id']=adb['id']
    @port=adb['port'].to_i
    @stat=Stat.new
    @watch=Watch::Stat.new
    ic=@cobj.list['internal']
    ic['set']="[key=val] .."
    ic['flush']="Flush Status"
    @prompt.table={'auto' => '@','watch' => '&', 'isu' => '*','na' => 'X' }
    @fint=nil
  end

  def shell
    if @fint
      modes={'frm' => "Frm mode",'app' => "App mode"}
      id='app'
      loop{
        case id
        when 'app'
          id=super(modes)
        when 'frm'
          id=@fint.shell(modes)
        else
          break
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
