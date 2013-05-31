#!/usr/bin/ruby
require "libsh"
require "libstatus"
require "libwatch"
require 'libfrmsh'
require "libappcmd"
require "libapprsp"
require "libsymupd"
require "libbuffer"
require "libsqlog"
require "thread"

module App
  def self.new(adb,fsh=nil)
    if fsh
      ash=App::Sv.new(adb,fsh,$opt['e'])
      ash=App::Cl.new(adb,'localhost') if $opt['c']
    elsif host=$opt['h'] or $opt['c']
      ash=App::Cl.new(adb,host)
    else
      ash=App::Test.new(adb)
    end
    ash
  end

  class Exe < Sh::Exe
    # @< cobj,output,upd_proc*
    # @ adb,fsh,watch,stat*
    attr_reader :adb,:stat
    def initialize(adb)
      @adb=Msg.type?(adb,Db)
      self['layer']='app'
      self['id']=@adb['site_id']
      @stat=Status::Var.new.ext_file(@adb['site_id'])
      plist={'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'}
      prom=Sh::Prompt.new(self,plist)
      super(@stat,prom)
      @cobj=Command.new(adb)
      @watch=Watch::Var.new.ext_file(@adb['site_id'])
      @cobj.int_proc=proc{
        int=@watch.interrupt
        verbose{"#{self['id']}/Interrupt:#{int}"}
        self['msg']="Interrupt #{int}"
      }
      init_view
    end

    private
    def shell_input(line)
      cmd=super
      cmd.unshift 'set' if /^[^ ]+\=/ === line
      cmd
    end

    def init_view
      @output=@print=Status::View.new(@adb,@stat).extend(Status::Print)
      @wview=Watch::View.new(@adb,@watch).ext_prt
      grp=@cobj['lo'].add_group('view',"Change View Mode")
      grp.add_item('pri',"Print mode").def_proc=proc{@output=@print}
      grp.add_item('wat',"Watch mode").def_proc=proc{@output=@wview} if @wview
      grp.add_item('raw',"Raw mode").def_proc=proc{@output=@stat}
      self
    end
  end

  class Test < Exe
    require "libsymupd"
    def initialize(adb)
      super
      @stat.ext_sym(adb).load
      @watch.ext_upd(adb,@stat).upd
      cri={:type => 'reg', :list => ['.']}
      @cobj['sv']['int'].add_item('set','[key=val,...]',[cri]).def_proc=proc{|item|
        @stat.str_update(item.par[0]).upd
        @watch.upd
        self['msg']="Set #{item.par[0]}"
      }
      @cobj['sv']['int'].add_item('del','[key,...]',[cri]).def_proc=proc{|item|
        item.par[0].split(',').each{|key|
          @stat['val'].delete(key)
        }
        @stat.upd
        @watch.upd
        self['msg']="Delete #{item.par[0]}"
      }
      @watch.event_proc=proc{|cmd,p|
        Msg.msg("#{cmd} is issued by event")
      }
      @cobj['sv'].def_proc=proc{|item|
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
    def initialize(adb,host=nil)
      super(adb)
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

  # @<< cobj,output,,upd_proc*
  # @< adb,watch,stat*
  # @ fsh,buf,log_proc
  class Sv < Exe
    def initialize(adb,fsh,logging=nil)
      super(adb)
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
      @buf=init_buf
      @cobj['sv']['ext'].def_proc=proc{|item|
        @watch.block?(item.cmd)
        sendcmd(1)
        verbose{"#{self['id']}/Issued:#{item.cmd},"}
        self['msg']="Issued"
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
            warning($!)
          end
          verbose{"Auto Update(#{@stat['time']})"}
          sleep int
        }
      }
    end
  end

  class List < Sh::DevList
    def initialize(current=nil)
      @ldb=Loc::Db.new
      if Frm::List === current
        @fl=current
        super(@ldb.list,@fl.current)
      elsif $opt['e'] || $opt['s']
        @fl=Frm::List.new(current)
        super(@ldb.list,@fl.current)
      else
        @fl={}
        super(@ldb.list,"#{current}")
      end
    end

    def newsh(id)
      App.new(@ldb.set(id)[:app],@fl[id])
    end
  end
end

if __FILE__ == $0
  ENV['VER']||='init/'
  Msg::GetOpts.new('cet')
  begin
    puts App::List.new(ARGV.shift).shell
  rescue InvalidID
    $opt.usage('(opt) [id]')
  end
end
