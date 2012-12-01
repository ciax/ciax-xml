#!/usr/bin/ruby
require "libappexe"
require 'libfrmlist'
require "libappcmd"
require "libapprsp"
require "libsymconv"
require "libbuffer"
require "libsqlog"
require "thread"

module App
  # @<< cobj,output,intdom,int_proc,upd_proc*
  # @< adb,extdom,output,watch,stat*
  # @ fint,buf,tid
  class Sv < Exe
    extend Msg::Ver
    def initialize(adb,fint,logging=nil)
      super(adb)
      Sv.init_ver("AppSv",9)
      @fint=Msg.type?(fint,Frm::Exe)
      update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
      @stat.ext_save.ext_rsp(@fint.field).ext_sym.upd
      @stat.ext_sqlog if logging and @fint.field.key?('ver')
      @watch.ext_conv(adb,@stat).ext_save.upd
      Thread.abort_on_exception=true
      @buf=Buffer.new(self)
      @buf.proc_send{@cobj.current.get}
      @buf.proc_recv{|fcmd| @fint.exe(fcmd)}
      @extdom.ext_appcmd.init_proc{|item|
        @watch.block?(item.cmd)
        @buf.send(1)
        Sv.msg{"#{self['id']}/Issued:#{item.cmd},"}
        self['msg']="Issued"
      }
      @watch.event_proc.add{|cmd,p|
        Sv.msg{"#{self['id']}/Auto(#{p}):#{cmd}"}
        @cobj.set(cmd)
        @buf.send(p)
      }
      gint=@intdom.add_group('int',"Internal Command")
      gint.add_item('interrupt').init_proc{
        int=@watch.interrupt
        Sv.msg{"#{self['id']}/Interrupt:#{int}"}
        self['msg']="Interrupt #{int}"
      }
      @buf.post_flush.add{
        @stat.upd.save
        @watch.upd.save
        sleep(@watch['interval']||0.1)
        # Auto issue by watch
        @watch.issue
      }
      # Update for Frm level manipulation
      @fint.int_proc.add{@stat.upd.save}
      # Logging if version number exists
      if logging and @stat['ver']
        @cobj.ext_logging('appcmd',@adb['site_id'],@adb['version']){
          @watch['active']
        }
      end
      @upd_proc.add{
        self['auto'] = @tid && @tid.alive?
        self['watch'] = @watch.active?
        self['na'] = !@buf.alive?
      }
      auto_update
      server(@adb['port']){to_j}
    end

    def auto_update
      @tid=Thread.new{
        tc=Thread.current
        tc[:name]="Auto"
        tc[:color]=4
        Thread.pass
        int=(@watch['period']||300).to_i
        loop{
          begin
            @cobj.set(['upd'])
            @buf.send(2)
          rescue InvalidID
            Msg.warn($!)
          end
          Int::Exe.msg{"Auto Update(#{@stat.get('time')})"}
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
