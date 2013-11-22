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
    # cfg should have ['frm'](Frm::List)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      if $opt['s'] or $opt['e']
        ash=App::Sv.new(cfg)
        cfg['host']='localhost'
      end
      ash=App::Cl.new(cfg) if $opt['c'] || (cfg['host']=$opt['h'])
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
        ext_shell(@output,{'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
        init_view
      end

      private
      def init_watch
        @watch=Watch::Data.new.set_db(@adb)
        @watch.upd_procs << proc{|wat|
          block=wat.data['block'].map{|id,par| par ? nil : id}.compact
          @cobj.extgrp.valid_sub(block)
        }
        @pre_procs << proc{|args|
          @watch.block?(args)
        }
      end

      def init_view
        @print.ext_prt
        @view_grp=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        @view_grp.add_item('sta',"Stat mode").set_proc{@output=@print;''}
        @view_grp.add_item('rst',"Raw Stat mode").set_proc{@output=@stat;''}
        return unless @watch
        @wview=Watch::View.new(@adb,@watch).ext_prt
        @view_grp.add_item('wat',"Watch mode").set_proc{@output=@wview;''}
        @view_grp.add_item('rwa',"Raw Watch mode").set_proc{@output=@watch;''}
      end

      def batch_interrupt
        @watch ? @watch.batch_on_interrupt : []
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
        @stat.ext_sym(@adb)
        @stat.upd_procs << proc{|st|st['time']=now_msec}
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
        return unless @watch
        @watch.ext_upd(@stat).upd.reg_procs(@stat)
        @watch.event_procs << proc{|p,args|
          Msg.msg("#{args} is issued by event")
        }
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super(cfg)
        host=type?(cfg['host']||@adb['host']||'localhost',String)
        if @watch
          @watch.ext_http(host)
          @watch.reg_procs(@stat) # @watch isn't relate to @stat
        end
        @stat.ext_http(host).load
        @post_procs << proc{@stat.load}
        ext_client(host,@adb['port'])
      end

    end

    class Sv < Exe
      def initialize(cfg)
        super(cfg)
        @fsh=type?(cfg['frm'][@id],Frm::Exe)
        @mode=@fsh.mode
        @stat.ext_rsp(@fsh.field).ext_sym(@adb).ext_file.upd
        update({'auto'=>nil,'watch'=>nil,'isu'=>nil,'na'=>nil})
        @buf=init_buf
        @cobj.ext_proc{|ent|
          verbose("AppSv","#@id/Issue:#{ent.id}")
          @buf.send(1,ent)
          "ISSUED"
        }
        @cobj.item_proc('interrupt'){|ent|
          batch_interrupt.each{|args|
            verbose("AppSv","Interrupt:#{args}")
            @buf.send(0,@cobj.set_cmd(args))
          }
          'INTERRUPT'
        }
        # Logging if version number exists
        if $opt['e'] && sv=@fsh.sqlsv
          sv.add_table(@stat)
          sv.add_table(@buf)
        end
        tid_auto=auto_update
        @post_procs << proc{
          self['auto'] = tid_auto && tid_auto.alive?
          self['na'] = !@buf.alive?
        }
        ext_watch
        ext_server(@adb['port'])
      end

      private
      def ext_watch
        return unless @watch
        @watch.ext_upd(@stat).ext_file.upd
        @watch.event_procs << proc{|p,args|
          verbose("AppSv","#@id/Auto(#{p}):#{args}")
          @buf.send(p,@cobj.set_cmd(args))
        }
        @watch.ext_logging if $opt['e'] && @stat['ver']
        @stat.upd_procs << proc{self['watch'] = @watch.active?}
        @interval=@watch['interval']
        @period=@watch['period']
      end

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
          sleep(@interval||0.1)
          # Auto issue by watch
          @watch.batch_on_event if @watch
        }
        buf
      end

      def auto_update
        Threadx.new("Update Thread(#@layer:#@id)",4){
          int=(@period||300).to_i
          loop{
            begin
              @buf.send(3,@cobj.set_cmd(['upd']))
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
        upper['frm']||=Frm::List.new
        upper['app']=self
        super
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
