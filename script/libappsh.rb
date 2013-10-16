#!/usr/bin/ruby
require 'libfrmsh'
require "libstatus"
require "libwatch"
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"
require "thread"

module CIAX
  module App
    # cfg should have ['frm'](Frm::List)
    def self.new(cfg)
      if $opt['s'] or $opt['e']
        ash=App::Sv.new(cfg)
        cfg['host']='localhost'
      end
      ash=App::Cl.new(cfg) if $opt['c'] || (cfg['host']=$opt['h'])
      ash||App::Test.new(cfg)
    end

    class Exe < Exe
      # @< cobj,output,upd_procs*
      # @ adb,fsh,watch,stat*
      attr_reader :adb,:stat
      def initialize(cfg)
        @adb=type?(cfg[:db],Db)
        cobj=Command.new(cfg)
        cobj.interrupt.set_proc{
          int=@watch.interrupt
          verbose("AppSh","#{self['id']}/Interrupt:#{int}")
          "INTERRUPT"
        }
        super('app',@adb['site_id']||@adb['id'],cobj)
        @stat=App::Status.new(@adb[:status][:struct].deep_copy)
        @stat['id']=self['id']
        ext_shell(@stat,{'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
        @watch=Watch::Data.new
        @pre_procs << proc{|args|@watch.block?(args)}
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
        grp=@cobj.lodom.add_group('caption'=>"Change View Mode")
        grp.add_item('pri',{:label =>"Print mode"}).set_proc{@output=@print;''}
        grp.add_item('wat',{:label =>"Watch mode"}).set_proc{@output=@wview;''} if @wview
        grp.add_item('raw',{:label =>"Raw mode"}).set_proc{@output=@stat;''}
        self
      end
    end

    class Test < Exe
      require "libappsym"
      def initialize(cfg)
        super
        @stat.ext_sym(@adb)
        @watch.ext_upd(@adb,@stat).upd
        @cobj.add_int
        @cobj.item_proc('set'){|ent|
          @stat.str_update(ent.par[0])
          "Set #{ent.par[0]}"
        }
        @cobj.item_proc('del'){|ent|
          ent.par[0].split(',').each{|key|
            @stat.unset(key)
          }
          "Delete #{ent.par[0]}"
        }
        @watch.event_proc=proc{|args,p|
          Msg.msg("#{args} is issued by event")
        }
        @upd_procs << proc{@watch.issue}
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super(cfg)
        host=type?(cfg['host']||@adb['host']||'localhost',String)
        @stat.ext_http(self['id'],host).load
        @watch.ext_http(self['id'],host).load
        ext_client(host,@adb['port'])
        @upd_procs << proc{
          @stat.load
          @watch.load
        }
      end
    end

    # @<< cobj,output,upd_procs*
    # @< adb,watch,stat*
    # @ fsh,buf,log_proc
    class Sv < Exe
      def initialize(cfg)
        super(cfg)
        @fsh=type?(cfg['frm'][self['id']],Frm::Exe)
        update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
        @stat.ext_rsp(@fsh.field,@adb[:status]).ext_sym(@adb).ext_file(self['id']).upd
        @watch.ext_upd(@adb,@stat).ext_file(self['id']).upd.event_proc=proc{|args,p|
          verbose("AppSv","#{self['id']}/Auto(#{p}):#{args}")
          @buf.send(p,@cobj.setcmd(args))
        }
        @buf=init_buf
        @cobj.ext_proc{|ent|
          verbose("AppSv","#{self['id']}/Issue:#{ent.args}")
          @buf.send(1,ent)
          "ISSUED"
        }
        # Logging if version number exists
        if $opt['e']
          @fsh.sqlsv.add_table(SqLog::Upd.new(@stat)) if @fsh.sqlsv
          ext_logging(@adb['site_id'],@adb['version'])if @adb['version']
        end
        tid_auto=auto_update
        @upd_procs << proc{
          self['auto'] = tid_auto && tid_auto.alive?
          self['watch'] = @watch.active?
          self['na'] = !@buf.alive?
        }
        ext_server(@adb['port'])
      end

      def ext_logging(id,ver=0)
        logging=Logging.new('issue',id,ver)
        @post_procs << proc{|args|
          logging.append({'cmd'=>args,'active'=>@watch.data['active']})
        }
        self
      end

      private
      def init_buf
        buf=Buffer.new(self)
        buf.send_proc{|ent|
          batch=type?(ent.cfg[:batch],Array)
          verbose("AppSv","Send FrmCmds #{batch}")
          batch
        }
        buf.recv_proc{|args|
          verbose("AppSv","Processing #{args}")
          @fsh.exe(args)
        }
        buf.flush_proc{
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
      def initialize(upper=Config.new)
        super
        @cfg['frm']||=Frm::List.new
      end

      def new_val(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:app]
        App.new(@cfg)
      end
    end

    if __FILE__ == $0
      ENV['VER']||='init/'
      GetOpts.new('chset')
      begin
        List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
