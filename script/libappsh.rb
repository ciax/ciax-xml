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
    def self.new(cfg,adb,fsh=nil)
      if Frm::Sv === fsh
        ash=App::Sv.new(cfg,adb,fsh,$opt['e'])
        ash=App::Cl.new(cfg,adb,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c']
        ash=App::Cl.new(cfg,adb,host)
      else
        ash=App::Test.new(cfg,adb)
      end
      ash
    end

    class Exe < Exe
      # @< cobj,output,upd_proc*
      # @ adb,fsh,watch,stat*
      attr_reader :adb,:stat
      def initialize(cfg,adb,id=nil)
        @adb=type?(adb,Db)
        cobj=ExtCmd.new(cfg,adb)
        cobj.int_proc{
          int=@watch.interrupt
          verbose("AppSh","#{self['id']}/Interrupt:#{int}")
          self['msg']="Interrupt #{int}"
        }
        super('app',id||adb['id'],cobj)
        @stat=App::Status.new(adb[:status][:struct].deep_copy)
        ext_shell(@stat,{'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
        @watch=Watch::Data.new
        @pre_proc << proc{|args|@watch.block?(args)}
        init_view
      end

      private
      def shell_input(line)
        args=super
        args.unshift 'set' if /^[^ ]+\=/ === line
        args
      end

      def init_view
        @output=@print=View.new(@adb,@stat).extend(Print)
        @wview=Watch::View.new(@adb,@watch).ext_prt
        grp=@cobj['lo'].add_group('view',"Change View Mode",3)
        grp.add_item('pri',"Print mode"){@output=@print}
        grp.add_item('wat',"Watch mode"){@output=@wview} if @wview
        grp.add_item('raw',"Raw mode"){@output=@stat}
        self
      end
    end

    class Test < Exe
      require "libappsym"
      def initialize(cfg,adb)
        super(cfg,adb)
        @stat.ext_sym(adb)
        @watch.ext_upd(adb,@stat).upd
        ig=@cobj['sv']['int']
        ig['set'].set_proc{|ent|
          @stat.str_update(ent.par[0])
          self['msg']="Set #{ent.par[0]}"
        }
        ig['del'].set_proc{|ent|
          ent.par[0].split(',').each{|key|
            @stat.unset(key)
          }
          self['msg']="Delete #{ent.par[0]}"
        }
        @watch.event_proc=proc{|args,p|
          Msg.msg("#{args} is issued by event")
        }
        @upd_proc << proc{@watch.issue}
      end
    end

    class Cl < Exe
      def initialize(adb,host=nil)
        super(cfg,adb,adb['site_id'])
        host=type?(host||adb['host']||'localhost',String)
        @stat.ext_http(self['id'],host).load
        @watch.ext_http(self['id'],host).load
        ext_client(host,adb['port'])
        @upd_proc << proc{
          @stat.load
          @watch.load
        }
      end
    end

    # @<< cobj,output,upd_proc*
    # @< adb,watch,stat*
    # @ fsh,buf,log_proc
    class Sv < Exe
      def initialize(adb,fsh,logging=nil)
        super(cfg,adb,adb['site_id'])
        @fsh=type?(fsh,Frm::Exe)
        update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
        @stat.ext_rsp(@fsh.field,adb[:status]).ext_sym(adb).ext_file(self['id']).upd
        if logging and @fsh.field.key?('ver')
          @fsh.sqlsv.init_table(SqLog::Upd.new(@stat))
        end
        @watch.ext_upd(adb,@stat).ext_file(self['id']).upd.event_proc=proc{|args,p|
          verbose("AppSv","#{self['id']}/Auto(#{p}):#{args}")
          @buf.send(p,@cobj.setcmd(args))
        }
        @buf=init_buf
        @cobj['sv']['ext'].set_proc{|ent|
          verbose("AppSv","#{self['id']}/Issue:#{ent.args}")
          @buf.send(1,ent)
          self['msg']="Issued"
        }
        # Logging if version number exists
        if logging and @adb['version']
          ext_logging(@adb['site_id'],@adb['version'])
        end
        tid_auto=auto_update
        @upd_proc << proc{
          self['auto'] = tid_auto && tid_auto.alive?
          self['watch'] = @watch.active?
          self['na'] = !@buf.alive?
        }
        ext_server(@adb['port'])
      end

      def ext_logging(id,ver=0)
        logging=Logging.new('issue',id,ver)
        @post_proc << proc{|args|
          logging.append({'cmd'=>args,'active'=>@watch.data['active']})
        }
        self
      end

      private
      def init_buf
        buf=Buffer.new(self)
        buf.send_proc{|ent|
          cmdary=ent.cfg[:cmdary]
          verbose("AppSv","Send FrmCmds #{cmdary}")
          cmdary
        }
        buf.recv_proc{|args|
          verbose("AppSv","Processing #{args}")
          @fsh.exe(args)
        }
        buf.flush_proc.add{
          verbose("AppSv","Flushed FrmCmds")
          @stat.upd.save
          sleep(@watch['interval']||0.1)
          # Auto issue by watch
          @watch.issue
        }
        buf
      end

      def auto_update
        Thread.new{
          tc=Thread.current
          tc[:name]="Update Thread(#{self['layer']}:#{self['id']})"
          tc[:color]=4
          Thread.pass
          int=(@watch['period']||300).to_i
          loop{
            begin
              @buf.send(2,@cobj.setcmd(['upd']))
            rescue InvalidID
              warning("AppSv",$!)
            end
            verbose("AppSv","Auto Update(#{@stat['time']})")
            sleep int
          }
        }
      end
    end

    class List < ShList
      def initialize(cfg=Config.new)
        cfg[:ldb]||=Loc::Db.new
        cfg[:fl]||=Frm::List.new
        super(){|id|
          adb=cfg[:ldb].set(id)[:app]
          App.new(cfg,adb,cfg[:fl][id])
        }
      end
    end

    if __FILE__ == $0
      ENV['VER']||='init/'
      GetOpts.new('cet')
      begin
        List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
