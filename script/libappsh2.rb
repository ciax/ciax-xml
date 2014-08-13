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
        ext_shell(@output){
          {'isu'=>'*'}.map{|k,v|
            v if self[k]
          }.join('')
        }
        init_view
      end

      private
      def init_view
        @print.ext_prt
        @view_grp=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        @view_grp.add_item('prt',"Print Stat mode").set_proc{@output=@print;''}
        @view_grp.add_item('raw',"Raw Stat mode").set_proc{@output=@stat;''}
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
          'ISSUED:'+ent.batch.inspect
        }
        @cobj.item_proc('set'){|ent|
          @stat.set(ent.par[0],ent.par[1])
          "SET:#{ent.par[0]}=#{ent.par[1]}"
        }
        @cobj.item_proc('del'){|ent|
          ent.par[0].split(',').each{|key| @stat.unset(key) }
          "DELETE:#{ent.par[0]}"
        }
        @cobj.item_proc('interrupt'){|ent|
          "INTERRUPT(#{batch_interrupt})"
        }
      end
    end

    class Cl < Exe
      def initialize(cfg)
        super(cfg)
        host=type?(cfg['host']||@adb['host']||'localhost',String)
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
        @cobj.ext_proc{|ent,src,pri|
          verbose("AppSv","#@id/Issuing:#{ent.id} from #{src} with priority #{pri}")
          @buf.send(pri,ent,src)
          "ISSUED"
        }
        @cobj.item_proc('interrupt'){|ent,src|
          batch_interrupt.each{|args|
            verbose("AppSv","#@id/Issuing:#{args} for Interrupt")
            @buf.send(0,@cobj.set_cmd(args),src)
          }
          warning("AppSv","Interrupt(#{batch_interrupt}) from #{src} with priority 0")
          'INTERRUPT'
        }
        # Logging if version number exists
        if sv=cfg[:sqlog]
          sv.add_table(@stat)
          sv.add_table(@buf)
        end
        ext_server(@adb['port'])
      end

      private
      def init_buf
        buf=Buffer.new(self)
        buf.send_proc{|ent|
          batch=type?(ent.batch,Array)
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
          @flush_procs.each{|p| p.call(self)}
        }
        buf
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
