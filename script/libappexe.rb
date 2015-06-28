#!/usr/bin/ruby
require "libexe"
require "libappdb"
require "libappview"
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"
require "libinsdb"
require "libsitelayer"

module CIAX
  $layers['a']=App
 module App
    def self.new(id,cfg={},attr={})
      Msg.type?(attr,Hash)
      if $opt.delete('l')
        attr['host']='localhost'
        Sv.new(id,cfg,attr)
      elsif host=$opt['h']
        attr['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(id,cfg,attr)
      else
        return Test.new(id,cfg,attr)
      end
      Cl.new(id,cfg,attr)
    end

    class Exe < Exe
      # cfg must have [:db],[:layers]
      attr_reader :adb,:stat,:host,:port
      attr_accessor :batch_interrupt
      def initialize(id,cfg={},attr={})
        super
        @cls_color=2
        @cfg[:site_id]=id
        # LayerDB might generated in List level
        @adb=type?(@cfg[:dbi]=@cfg[:db].get(id),Dbi)
        @cfg[:frm_site]=@adb['frm_site']
        @fsh=@cfg[:layers].get('frm').get(@cfg[:frm_site])
        @site_stat=@fsh.site_stat.add_db('isu' => '*')
        @host=type?(@cfg['host']||@adb['host']||'localhost',String)
        @port=@adb['port']
        @stat=@cfg[:stat]=Status.new.set_db(@adb)
        @appview=View.new(@adb,@stat)
        @output=$opt['j'] ? @stat : @appview
        @batch_interrupt=[]
        @cobj=Index.new(@cfg)
      end

      def ext_shell
        super
        vg=@cobj.loc.add_view
        vg['vis'].cfg.proc{@output=@appview;''}
        vg['raw'].cfg.proc{@output=@stat;''}
        self
      end
    end

    class Test < Exe
      def initialize(id,cfg={},attr={})
        super
        @stat.ext_sym
        @stat.post_upd_procs << proc{|st|
          verbose("App","Propagate Status#upd -> App#settime")
          st['time']=now_msec
        }
        @cobj.rem.add_int
        @cobj.rem.ext.cfg.proc{|ent|
          @stat.upd
          ent.cfg.path
        }
        @cobj.item_proc('interrupt'){|ent|
          "INTERRUPT(#{@batch_interrupt})"
        }
      end
    end

    class Cl < Exe
      def initialize(id,cfg={},attr={})
        super
        @stat.ext_http(@host)
        @pre_exe_procs << proc{@stat.upd}
        ext_client(@host,@port)
      end
    end

    class Sv < Exe
      require "libfrmlist"
      # cfg(attr) must have layers[:frm]
      def initialize(id,cfg={},attr={})
        super
        @stat.ext_rsp(@fsh.field).ext_sym.ext_file
        @buf=init_buf
        ver=@stat['ver']
        @fsh.flush_procs << proc{
          verbose("AppSv","Propagate Frm::Exe#flush -> Buffer#flush")
          @buf.flush
        }
        @cobj.rem.ext.cfg.proc{|ent,src,pri|
          verbose("AppSv","#@id/Issuing:#{ent.id} from #{src} with priority #{pri}")
          @buf.send(pri,ent,src)
          "ISSUED"
        }
        @cobj.item_proc('interrupt'){|ent,src|
          @batch_interrupt.each{|args|
            verbose("AppSv","#@id/Issuing:#{args} for Interrupt")
            @buf.send(0,@cobj.set_cmd(args),src)
          }
          warning("AppSv","Interrupt(#{@batch_interrupt}) from #{src}")
          'INTERRUPT'
        }
        # Logging if version number exists
        if sv=@cfg[:sqlog]
          sv.add_table(@stat)
        end
        ext_server(@port)
      end

      private
      def server_output
        Hashx.new.update(@site_stat).update(self).to_j
      end

      def init_buf
        buf=Buffer.new(@stat['id'],@stat['ver'],@site_stat)
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
          verbose("AppSv","Propagate Buffer#flush -> Status#upd")
          @stat.upd
          sleep(@interval||0.1)
          # Auto issue by watch
        }
        buf.server
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      cfg=Config.new
      cfg[:jump_groups]=[]
      cfg[:layers]=Site::Layer.new(cfg).add_layer(Frm,Dev)
      cfg[:db]=Ins::Db.new
      begin
        App.new(ARGV.shift,cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
