#!/usr/bin/ruby
require "libappexe"
require 'libfrmlist'
require "libappcmd"
require "libapprsp"
require "libsymconv"
require "libsqlog"
require "thread"

module App
  class Sv < Exe
    def initialize(adb,fint)
      super(adb)
      @fint=Msg.type?(fint,Frm::Exe)
      update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
      @stat.ext_save.ext_rsp(@fint.field).ext_sym.upd
      @stat.ext_sqlog if @fint.field.key?('ver')
      @stat.ext_watch_w
      Thread.abort_on_exception=true
      @cobj.values.each{|item|
        item.extend(App::Cmd)
      }
      @buf=Buffer.new(self)
      @buf.proc_send{@cobj.current.get}
      @buf.proc_recv{|fcmd| @fint.exe(fcmd)}
      @extcmd.init_proc{|item|
        @stat.block?(item.cmd)
        @buf.send(1)
        self['msg']="Issued"
      }
      @stat.event_proc=proc{|cmd,p|
          @cobj.set(cmd)
          @buf.send(p)
      }
      gint=@intcmd.add_group('int',"Internal Command")
      gint.add_item('interrupt').init_proc{
        int=@stat.interrupt
        self['msg']="Interrupt #{int}"
      }
      @buf.post_flush.add{
        @stat.upd.save
        sleep(@stat.interval||0.1)
        # Auto issue by watch
        @stat.issue
      }
      # Update for Frm level manipulation
      @fint.int_proc.add{@stat.upd.save}
      # Logging if version number exists
      if @stat.ver
        @cobj.ext_logging(@adb['site'],@stat.ver){@stat.active}
      end
      @upd_proc.add{
        self['auto'] = @tid && @tid.alive?
        self['watch'] = @stat.active?
        self['na'] = !@buf.alive?
      }
      auto_update
      ext_server(@adb['port'])
    end

    def auto_update
      @tid=Thread.new{
        tc=Thread.current
        tc[:name]="Auto"
        tc[:color]=4
        Thread.pass
        int=(@stat.period||300).to_i
        loop{
          begin
            @cobj.set(['upd'])
            @buf.send(2)
          rescue InvalidID
            Msg.warn($!)
          end
          Int::Server.msg{"Auto Update(#{@stat.get('time')})"}
        sleep int
        }
      }
      self
    end

    def app_shell
      extend(Sh).app_shell(@fint)
      self
    end
  end
end
