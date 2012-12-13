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
  # @ fint,buf,log_proc
  class Sv < Exe
    extend Msg::Ver
    def initialize(adb,fint,logging=nil)
      super(adb)
      Sv.init_ver("AppSv",9)
      @fint=Msg.type?(fint,Frm::Exe)
      update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
      @stat.ext_save.ext_rsp(@fint.field).ext_sym.upd
      @stat.ext_sqlog if logging and @fint.field.key?('ver')
      @watch.ext_conv(adb,@stat).ext_save.upd.event_proc.add{|cmd,p|
        Sv.msg{"#{self['id']}/Auto(#{p}):#{cmd}"}
        @cobj.setcmd(cmd)
        sendcmd(p)
      }
      Thread.abort_on_exception=true
      @buf=init_buf
      @extdom.ext_appcmd.init_proc{|item|
        @watch.block?(item.cmd)
        sendcmd(1)
        Sv.msg{"#{self['id']}/Issued:#{item.cmd},"}
        self['msg']="Issued"
      }
      grp=@intdom.add_group('int',"Internal Command")
      grp.add_item('interrupt').init_proc{
        int=@watch.interrupt
        Sv.msg{"#{self['id']}/Interrupt:#{int}"}
        self['msg']="Interrupt #{int}"
      }
      # Update for Frm level manipulation
      @fint.int_proc.add{@stat.upd.save}
      # Logging if version number exists
      @log_proc=UpdProc.new
      if logging and @adb['version']
        ext_logging(@adb['site_id'],@adb['version'])
      end
      tid_auto=auto_update
      @upd_proc.add{
        self['auto'] = tid_auto && tid_auto.alive?
        self['watch'] = @watch.active?
        self['na'] = !@buf.alive?
      }
      server(@adb['port']){to_j}
    end

    def ext_logging(id,ver=0)
      logging=Logging.new('issue',id,ver){
        {'cmd'=>@cobj.current[:cmd],'active'=>@watch['active']}
      }
      @log_proc.add{logging.append}
      self
    end

    private
    def sendcmd(p)
      @buf.send(p)
      @log_proc.upd
      self
    end

    def init_buf
      buf=Buffer.new(self)
      buf.send_proc{@cobj.current.getcmd}
      buf.recv_proc{|fcmd| @fint.exe(fcmd)}
      buf.flush_proc.add{
        @stat.upd.save
        @watch.upd.save
        sleep(@watch['interval']||0.1)
        # Auto issue by watch
        @watch.issue
      }
      buf
    end

    def auto_update
      Thread.new{
        tc=Thread.current
        tc[:name]="Auto"
        tc[:color]=4
        Thread.pass
        int=(@watch['period']||300).to_i
        loop{
          begin
            @cobj.setcmd(['upd'])
            sendcmd(2)
          rescue InvalidID
            Msg.warn($!)
          end
          Int::Exe.msg{"Auto Update(#{@stat.get('time')})"}
        sleep int
        }
      }
    end

    def app_shell
      extend(Sh).app_shell(@fint)
      self
    end
  end
end
