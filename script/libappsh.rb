#!/usr/bin/ruby
require "libsh"
require "libstatus"
require "libwatch"
require 'libfrmsh'
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"
require "thread"

module CIAX
  module App
    def self.new(adb,fsh=nil)
      if Frm::Sv === fsh
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
      def initialize(adb,id=nil)
        @adb=type?(adb,Db)
        self['layer']='app'
        self['id']=id||adb['id']
        cobj=ExtCmd.new(adb)
        @stat=App::Status.new(adb[:status][:struct].deep_copy)
        plist={'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'}
        prom=Sh::Prompt.new(self,plist)
        super(cobj)
        ext_shell(@stat,prom)
        @watch=Watch::Data.new
        @cobj.int_proc=proc{
          int=@watch.interrupt
          verbose("AppSh","#{self['id']}/Interrupt:#{int}")
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
        @output=@print=View.new(@adb,@stat).extend(Print)
        @wview=Watch::View.new(@adb,@watch).ext_prt
        grp=@cobj['lo'].add_group('view',"Change View Mode")
        grp.add_item('pri',"Print mode").def_proc=proc{@output=@print}
        grp.add_item('wat',"Watch mode").def_proc=proc{@output=@wview} if @wview
        grp.add_item('raw',"Raw mode").def_proc=proc{@output=@stat}
        self
      end
    end

    class Test < Exe
      require "libappsym"
      def initialize(adb)
        super(adb)
        @stat.ext_sym(adb)
        @watch.ext_upd(adb,@stat).upd
        cri={:type => 'reg', :list => ['.']}
        @cobj['sv']['int'].add_item('set','[key=val,...]',[cri]).def_proc=proc{|item|
          @stat.str_update(item.par[0])
          self['msg']="Set #{item.par[0]}"
        }
        @cobj['sv']['int'].add_item('del','[key,...]',[cri]).def_proc=proc{|item|
          item.par[0].split(',').each{|key|
            @stat.unset(key)
          }
          self['msg']="Delete #{item.par[0]}"
        }
        @watch.event_proc=proc{|cmd,p|
          Msg.msg("#{cmd} is issued by event")
        }
        @cobj['sv'].def_proc=proc{|item|
          @watch.block?(item.cmd)
          @stat.upd
        }
        @upd_proc.add{
          @watch.issue
        }
      end
    end

    class Cl < Exe
      def initialize(adb,host=nil)
        super(adb,adb['site_id'])
        host=type?(host||adb['host']||'localhost',String)
        @stat.ext_http(self['id'],host).load
        @watch.ext_http(self['id'],host).load
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
        super(adb,adb['site_id'])
        @fsh=type?(fsh,Frm::Exe)
        update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
        @stat.ext_rsp(@fsh.field,adb[:status]).ext_sym(adb).ext_file(self['id']).upd
        SqLog::Upd.new(@stat).ext_exec if logging and @fsh.field.key?('ver')
        @watch.ext_upd(adb,@stat).ext_file(self['id']).upd.event_proc=proc{|cmd,p|
          verbose("AppSv","#{self['id']}/Auto(#{p}):#{cmd}")
          @item=@cobj.setcmd(cmd)
          sendcmd(p,@item)
        }
        @buf=init_buf
        @cobj['sv']['ext'].def_proc=proc{|item|
          @watch.block?(item.cmd)
          verbose("AppSv","#{self['id']}/Issue:#{item.cmd}")
          sendcmd(1,item)
          self['msg']="Issued"
        }
        # Update for Frm level manipulation
        #      @fsh.upd_proc.add{@stat.upd.save}
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
        logging=Logging.new('issue',id,ver)
        @log_proc.add{
          logging.append({'cmd'=>@item[:cmd],'active'=>@watch['active']})
        }
        self
      end

      private
      def sendcmd(p,item)
        verbose("AppSv","#{self['id']}/Issue2:#{item.cmd}")
        @buf.send(p,item)
        @log_proc.upd
        self
      end

      def init_buf
        buf=Buffer.new(self)
        buf.send_proc{|item|
          cmds=item.getcmd
          verbose("AppSv","Send FrmCmds #{cmds}")
          cmds
        }
        buf.recv_proc{|fcmd|
          verbose("AppSv","Processing #{fcmd}")
          @fsh.exe(fcmd)
        }
        buf.flush_proc.add{
          verbose("AppSv","Flushed FrmCmds")
          @stat.upd.save
          @watch.save
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
              @item=@cobj.setcmd(['upd'])
              sendcmd(2,@item)
            rescue InvalidID
              warning("AppSv",$!)
            end
            verbose("AppSv","Auto Update(#{@stat['time']})")
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
    GetOpts.new('cet')
    begin
      puts App::List.new(ARGV.shift).shell
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
