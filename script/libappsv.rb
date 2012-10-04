#!/usr/bin/ruby
require "libappsh"
require "libappcmd"
require "libapprsp"
require "libsymconv"
require "libsqlog"
require "thread"

module App
  class Sv < Sh
    attr_reader :fint
    def initialize(adb)
      super(adb)
      update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
      id=adb['id']
      @stat.ext_save.ext_rsp(@fint.field).ext_sym.upd
      @stat.ext_sqlog if @fint.field.key?('ver')
      @stat.ext_watch_w
      Thread.abort_on_exception=true
      @cobj.values.each{|item|
        item.extend(App::Cmd)
      }
      @buf=Buffer.new(self)
      @buf.proc_send{@cobj.current.get}
      @buf.proc_recv{|fcmd| @fint.exe(fcmd) }
      @cobj.ext.def_proc << proc{
        @buf.send(1)
        "Issued"
      }
      @cobj.pre_proc << proc{|par,id|
        cmd=[id,*par]
        Msg.cmd_err("Blocking(#{cmd})") if @stat.block?(cmd)
      }
      gint=@cobj.int.add_group('int',"Internal Command")
      gint.add_item('interrupt').set_proc{
        int=@stat.interrupt.each{|cmd|
          @cobj.set(cmd)
          @buf.send(0)
        }
        "Interrupt #{int}"
      }
      @buf.post_flush << proc{
        @stat.upd.save
        sleep(@stat.interval||0.1)
        # Auto issue by watch
        @stat.issue.each{|cmd|
          @cobj.set(cmd)
          @buf.send(2)
        }
      }
      # Update for Frm level manipulation
      @fint.post_proc << proc{@stat.upd}
      # Logging if version number exists
      if @stat.ver
        @cobj.ext_logging(id,@stat.ver){@stat.active}
      end
      auto_update
      extend(Int::Server)
    end

    def server(type='app',json=true)
      super
    end

    private
    def prompt
      self['auto'] = @tid && @tid.alive?
      self['watch'] = @stat.active?
      self['na'] = !@buf.alive?
      super
    end

    def auto_update
      @tid=Thread.new{
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
  end
end
