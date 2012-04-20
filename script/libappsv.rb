#!/usr/bin/ruby
require "libappobj"
require "libappcmd"
require "libbuffer"
require "thread"
require "json"
require "libmodlog"

class AppSv < AppObj
  attr_reader :fint
  def initialize(adb,fint)
    super(adb)
    id=adb['id']
    @fint=Msg.type?(fint,FrmObj)
    @ac=AppCmd.new(@cobj)
    val=AppVal.new(adb,@fint.field).upd
    @stat.extend(Stat::Convert).init(adb,val)
    @stat.extend(Stat::Logging) if @fint.field.key?('ver')
    @watch.extend(Watch::Convert).init(adb,val).extend(IoFile).init(id)
    Thread.abort_on_exception=true
    @buf=Buffer.new.thread{|fcmd| @fint.exe(fcmd) }
    @buf.at_flush << proc{
      @stat.upd.save
      @watch.upd.save
      sleep (@watch.interval||0.1)
      sendfrm(@watch.issue,2)
    }
    @fint.updlist << proc {
      @stat.upd.save
      @watch.upd.save
    }
    # Logging if version number exists
    extend(Logging).init('appcmd',id,@stat['ver']) if @stat.key?('ver')
    auto_update
    upd_prompt
  end

  #cmd is array
  def exe(cmd)
    msg=''
    case cmd.first
    when nil
    when 'interrupt'
      int=@watch.interrupt
      sendfrm(int,0)
      msg="Interrupt #{int}"
    when 'flush'
      @fint.field.load
      @buf.at_flush.upd
    when 'set'
      hash={}
      cmd[1..-1].each{|s|
        k,v=s.split('=')
        hash[k]=v
      }
      @stat.set(hash).save
      @watch.upd.save
      msg="Set #{hash}"
    else
      if @watch.block?(cmd)
        msg="Blocking(#{cmd})"
      else
        sendfrm([cmd])
        msg="ISSUED"
      end
    end
    upd_prompt
    msg
  end

  def socket(type='app')
    super
  end

  private
  def upd_prompt
    @prompt['auto'] = @tid && @tid.alive?
    @prompt['watch'] = @watch.active?
    @prompt['isu'] = @buf.issue
    @prompt['na'] = !@buf.alive?
    self
  end

  # ary is bunch of appcmd array (ary of ary)
  def sendfrm(ary,pri=1)
    @buf.send(pri){
      # Making bunch of frmcmd array (ary of ary)
      ary.map{|cmd|
        @cobj.set(cmd)
        append(cmd){@watch.act_list}
        @ac.get
      }.flatten(1)
    }
  end

  def append(cmd);end

  def auto_update
    @tid=Thread.new{
      Thread.pass
      int=(@watch.period||300).to_i
      cmd=[['upd']]
      loop{
        begin
          sendfrm(cmd,2)
        rescue SelectID
          Msg.warn($!)
        end
        @v.msg{"Auto Update(#{@stat['val']['time']})"}
        sleep int
      }
    }
    self
  end
end
