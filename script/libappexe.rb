#!/usr/bin/ruby
require "libsh"
require "libstatus"
require "libwatch"

module App
  class Exe < Sh::Exe
    # @< cobj,output,intgrp,interrupt,upd_proc*
    # @ adb,fint,extdom,watch,stat*
    attr_reader :stat
    def initialize(adb,fint)
      @adb=Msg.type?(adb,Db)
      self['id']=@adb['site_id']
      @fint=Msg.type?(fint,Frm::Exe)
      @stat=Status::Var.new.ext_file(@adb['site_id'])
      super(@stat,{'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
      @extdom=@cobj.add_extdom(@adb,:command)
      @watch=Watch::Var.new.ext_file(@adb['site_id'])
      if aldb=@adb[:command][:alias]
        aldb.each{|k,v| @cobj[k]=@cobj[v]}
      end
      init_layer
      init_view
      self
    end

    private
    def shell_conv(line)
      line='set '+line if /^[^ ]+\=/ === line
      line
    end

    def init_layer
      @fint.set_switch('lay',"Change Layer",{'app'=>"App mode"})
      grp=@shdom.add_group('lay',"Change Layer")
      grp.update_items({'frm'=>"Frm mode"}).reset_proc{|item|
        @fint.shell || exit
      }
      self
    end

    def init_view
      @output=@print=Status::View.new(@adb,@stat).extend(Status::Print)
      @wview=Watch::View.new(@adb,@watch).ext_prt
      grp=@shdom.add_group('view',"Change View Mode")
      grp.add_item('pri',"Print mode").reset_proc{@output=@print}
      grp.add_item('wat',"Watch mode").reset_proc{@output=@wview} if @wview
      grp.add_item('raw',"Raw mode").reset_proc{@output=@stat}
      self
    end
  end

  class Test < Exe
    require "libsymupd"
    def initialize(adb,fint)
      super
      @stat.ext_sym(adb).load
      @watch.ext_upd(adb,@stat).upd
      cri={:type => 'reg', :list => ['.']}
      @intgrp.add_item('set','[key=val,...]',[cri]).reset_proc{|item|
        @stat.str_update(item.par[0]).upd
        @watch.upd
        self['msg']="Set #{item.par[0]}"
      }
      @intgrp.add_item('del','[key,...]',[cri]).reset_proc{|item|
        item.par[0].split(',').each{|key|
          @stat['val'].delete(key)
        }
        @stat.upd
        @watch.upd
        self['msg']="Delete #{item.par[0]}"
      }
      @interrupt.reset_proc{
        int=@watch.interrupt
        self['msg']="Interrupt #{int}"
      }
      @watch.event_proc=proc{|cmd,p|
        Msg.msg("#{cmd} is issued by event")
      }
      @cobj.def_proc.set{|item|
        @watch.block?(item.cmd)
        @stat.upd
        @watch.upd
      }
      @upd_proc.add{
        @watch.issue
      }
    end
  end

  class Cl < Exe
    def initialize(adb,fint,host=nil)
      super(adb,fint)
      host=Msg.type?(host||adb['host']||'localhost',String)
      @stat.ext_url(host).load
      @watch.ext_url(host).load
      ext_client(host,adb['port'])
      @upd_proc.add{
        @stat.load
        @watch.load
      }
    end
  end
end
