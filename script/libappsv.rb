#!/usr/bin/ruby
require "libappsh"
require 'libfrmlist'
require "libappcmd"
require "libapprsp"
require "libsymupd"
require "libbuffer"
require "libsqlog"
require "thread"

module App
  # @<< cobj,output,intgrp,interrupt,upd_proc*
  # @< adb,extdom,watch,stat*
  # @ fsh,buf,log_proc
  class Sv < Exe
    def initialize(adb,fsh,logging=nil)
      super(adb,fsh)
      init_ver("AppSv",9)
      @fsh=Msg.type?(fsh,Frm::Exe)
      update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
      @stat.ext_save.ext_rsp(@fsh.field,adb[:status]).ext_sym(adb).upd
      @stat.ext_sqlog.ext_exec if logging and @fsh.field.key?('ver')
      @watch.ext_upd(adb,@stat).ext_save.upd.event_proc=proc{|cmd,p|
        verbose{"#{self['id']}/Auto(#{p}):#{cmd}"}
        @cobj.setcmd(cmd)
        sendcmd(p)
      }
      Thread.abort_on_exception=true
      @buf=init_buf
      @extdom.ext_appcmd.reset_proc{|item|
        @watch.block?(item.cmd)
        sendcmd(1)
        verbose{"#{self['id']}/Issued:#{item.cmd},"}
        self['msg']="Issued"
      }

      @interrupt.reset_proc{
        int=@watch.interrupt
        verbose{"#{self['id']}/Interrupt:#{int}"}
        self['msg']="Interrupt #{int}"
      }
      # Update for Frm level manipulation
      @fsh.upd_proc.add{@stat.upd.save}
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
      ext_server(@adb['port'])
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
      buf.recv_proc{|fcmd|@fsh.exe(fcmd)}
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
          verbose{"Auto Update(#{@stat['time']})"}
          sleep int
        }
      }
    end
  end
end
