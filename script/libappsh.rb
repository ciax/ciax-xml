#!/usr/bin/ruby
require 'libfrmsh'
require "libappview"
require "libwatview"
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"
require "thread"

module CIAX
  module App
    # cfg should have [:frm_list](Frm::List)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      if $opt['s'] or $opt['e']
        ash=App::Sv.new(cfg)
        cfg['host']='localhost'
      end
      ash=App::Cl.new(cfg) if (cfg['host']=$opt['h']) || $opt['c']
      ash||App::Test.new(cfg)
    end

    class Exe < Exe
      attr_reader :adb,:stat
      def initialize(cfg)
        @adb=type?(cfg[:db],Db)
        @stat=Status.new.set_db(@adb)
        super('app',@stat['id'],Command.new(cfg))
        @output=@print=View.new(@adb,@stat)
        init_watch if @adb[:watch]
        ext_shell(@output){
          {'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'}.map{|k,v|
            v if self[k]
          }.join('')
        }
        init_view
      end

      private
      def init_watch
        @event=Watch::Event.new.set_db(@adb)
        @event.post_upd_procs << proc{|wat|
          block=wat.data['block'].map{|id,par| par ? nil : id}.compact
          @cobj.extgrp.valid_sub(block)
        }
        @pre_exe_procs << proc{|args|
          @event.block?(args)
        }
      end

      def init_view
        @print.ext_prt
        @view_grp=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        @view_grp.add_item('sta',"Stat mode").set_proc{@output=@print;''}
        @view_grp.add_item('rst',"Raw Stat mode").set_proc{@output=@stat;''}
        return unless @event
        @wview=Watch::View.new(@adb,@event).ext_prt
        @view_grp.add_item('wat',"Watch mode").set_proc{@output=@wview;''}
        @view_grp.add_item('rwa',"Raw Watch mode").set_proc{@output=@event;''}
      end

      def batch_interrupt
        @event ? @event.batch_on_interrupt : []
      end

      def shell_input(line)
        args=super
        args.unshift 'set' if /^[^ ]+\=/ === line
        args
      end
    end

    class Test < Exe
      require "libappsym"
      def initialize(cfg)
        super
        @mode='TEST'
        @stat.ext_sym
        @stat.post_upd_procs << proc{|st|st['time']=now_msec}
        @cobj.add_int
        @cobj.ext_proc{|ent|
          @stat.upd
          'ISSUED:'+ent.cfg[:batch].inspect
        }
        @cobj.item_proc('set'){|ent|
          @stat.str_update(ent.par[0])
          "SET:#{ent.par[0]}"
        }
        @cobj.item_proc('del'){|ent|
          ent.par[0].split(',').each{|key| @stat.unset(key) }
          "DELETE:#{ent.par[0]}"
        }
        @cobj.item_proc('interrupt'){|ent|
          "INTERRUPT(#{batch_interrupt})"
        }
        ext_watch
      end

      def ext_watch
        return unless @event
        @event.ext_rsp(@stat)
        @event.event_procs << proc{|p,args|
          Msg.msg("#{args} is issued by event")
        }
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super(cfg)
        host=type?(cfg['host']||@adb['host']||'localhost',String)
        if @event
          @event.ext_http(host)
          @stat.post_upd_procs << proc{@event.upd} # @event is independent from @stat
        end
        @stat.ext_http(host)
        @pre_exe_procs << proc{@stat.upd}
        ext_client(host,@adb['port'])
      end
    end

    class Sv < Exe
      def initialize(cfg)
        super(cfg)
        @fsh=type?(cfg[:frm_list][@id],Frm::Exe)
        @mode=@fsh.mode
        @stat.ext_rsp(@fsh.field).ext_sym.ext_file
        update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
        @buf=init_buf
        ver=@buf['ver']=@stat['ver']
        @fsh.flush_procs << proc{ @buf.flush }
        @cobj.ext_proc{|ent,src|
          verbose("AppSv","#@id/Issue:#{ent.id} from #{src}")
          @buf.send(1,ent,src)
          "ISSUED"
        }
        @cobj.item_proc('interrupt'){|ent,src|
          batch_interrupt.each{|args|
            verbose("AppSv","Interrupt:#{args} from #{src}")
            @buf.send(0,@cobj.set_cmd(args),src)
          }
          warning("AppSv","Interrupt(#{batch_interrupt})")
          'INTERRUPT'
        }
        # Logging if version number exists
        if sv=cfg[:sqlog]
          sv.add_table(@stat)
          sv.add_table(@buf)
        end
        tid_auto=auto_update
        @post_exe_procs << proc{
          self['auto'] = tid_auto && tid_auto.alive?
          self['na'] = !@buf.alive?
        }
        ext_watch
        ext_server(@adb['port'])
      end

      private
      def ext_watch
        return unless @event
        @event.ext_rsp(@stat).ext_file
        @event.event_procs << proc{|p,args|
          verbose("AppSv","#@id/Auto(#{p}):#{args}")
          @buf.send(p,@cobj.set_cmd(args),'event')
        }
        @event.ext_logging if $opt['e'] && @stat['ver']
        @stat.post_upd_procs << proc{self['watch'] = @event.active?}
        @interval=@event['interval']
        @period=@event['period']
      end

      def init_buf
        buf=Buffer.new(self)
        buf.send_proc{|ent|
          batch=type?(ent.cfg[:batch],Array)
          verbose("AppSv","Send FrmCmds #{batch}")
          batch
        }
        buf.recv_proc{|args,src|
          verbose("AppSv","Processing #{args}")
          @fsh.exe(args,src)
        }
        buf.flush_proc{
          verbose("AppSv","Flushed FrmCmds")
          @stat.upd
          sleep(@interval||0.1)
          # Auto issue by watch
          @event.batch_on_event if @event
        }
        buf
      end

      def auto_update
        Threadx.new("Update Thread(#@layer:#@id)",4){
          int=(@period||300).to_i
          loop{
            sleep int
            begin
              @buf.send(3,@cobj.set_cmd(['upd']),'auto')
            rescue InvalidID
              errmsg
            end
            verbose("AppSv","Auto Update(#{@stat['time']})")
          }
        }
      end
    end

    class List < Site::List
      def initialize(upper=nil)
        super(upper)
        @cfg[:frm_list]||=Frm::List.new(@cfg)
      end

      def add(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:adb]
        @cfg[:sqlog]||=SqLog::Save.new(id,'App')
        jumpgrp(App.new(@cfg))
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
