#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "libappcmd"
require "libwview"
require "libprint"
require "libbuffer"
require "libwatch"
require "thread"

class AppObj
  attr_reader :prompt,:message
  def initialize(adb,frmobj)
    @v=Msg::Ver.new("appobj",9)
    Msg.type?(adb,AppDb)
    @prompt=''
    @id=adb['id']
    @fobj=frmobj
    @par=Param.new(adb[:command])
    @ac=AppCmd.new(@par)
    @view=Wview.new(@id,adb,@fobj.field)
    @output=@print=Print.new(adb,@view)
    Thread.abort_on_exception=true
    @buf=Buffer.new
    @interval=(adb['interval']||1).to_i
    @watch=Watch.new(adb,@view)
    @wth=watch_thread unless adb[:watch].empty?
    @cth=command_thread
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add('set'=>"[key=val] ..")
    @cl.add('sleep'=>"sleep [sec]")
    @cl.add('waitfor'=>"[key=val] (timeout=10)")
    @cl.add('view'=>"View mode")
    @cl.add('raw'=>"Raw Stat mode")
    @cl.add('watch'=>"Watch mode")
    upd_prompt
  end

  def upd(cmd)
    @message=nil
    case cmd.first
    when nil
    when 'view'
      @output=@print
    when 'raw'
      @output=@view['stat']
    when 'watch'
      @output=@watch
    when 'interrupt'
      stop=@watch.interrupt
      @buf.interrupt{stop}
      @message="Interrupt #{stop}"
    when 'sleep'
      @buf.wait_for(cmd[1].to_i){}
      @message="Sleeping"
    when 'waitfor'
      k,v=cmd[1].split('=')
      @buf.wait_for(10){ @view.stat(k) == v }
      @message="Waiting"
    when 'set'
      hash={}
      cmd[1..-1].each{|s|
        k,v=s.split('=')
        hash[k]=v
      }
      @view.set(hash).save
      @message="Set #{hash}"
    else
      if @watch.block_pattern === cmd.join(' ')
        @message="Blocking(#{@watch.block_pattern.inspect})"
      else
        @par.set(cmd)
        @buf.send(@ac.getcmd)
        @message="ISSUED"
      end
    end
    upd_prompt
    self
  rescue SelectCMD
    @cl.error
  end

  def to_s
    @output.to_s
  end

  private
  def upd_prompt
    @prompt.replace(@id)
    @prompt << '@' if @wth && @wth.alive?
    @prompt << '&' if @watch.active?
    @prompt << '*' if @buf.issue
    @prompt << '#' if @buf.wait
    @prompt << (@cth.alive? ? '>' : 'X')
    self
  end

  def command_thread
    Thread.new{
      Thread.pass
      loop{
        begin
          @fobj.upd(@buf.recv)
          @v.msg{"Field Updated(#{@fobj.field['time']})"}
          @view.upd.save
          @v.msg{"Status Updated(#{@view['stat']['time']})"}
        rescue UserError
          warn $!
          Msg.alert(" in Command Thread")
          @buf.clear
        end
      }
    }
  end

  def watch_thread
    Thread.new{
      Thread.pass
      loop{
        begin
          @buf.auto{
            @watch.upd.issue.map{|cmd|
              @par.set(cmd)
              @ac.getcmd
            }.flatten(1)
          }
        rescue SelectID
          Msg.warn($!)
        end
        sleep @interval
      }
    }
  end
end
