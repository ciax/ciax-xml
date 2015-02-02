#!/usr/bin/ruby
require 'libfrmexe'
require "libappview"
require "libwatview"
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"

module CIAX
  module App
    # cfg should have [:frm_list](Frm::List)
    def self.new(cfg)
      Msg.type?(cfg,Hash)
      if $opt.delete('l')
        cfg['host']='localhost'
        Sv.new(cfg)
      elsif host=$opt['h']
        cfg['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(cfg)
      else
        return Test.new(cfg)
      end
      Cl.new(cfg)
    end

    class Exe < Exe
      attr_reader :adb,:stat
      attr_accessor :batch_interrupt
      def initialize(cfg)
        @adb=type?(cfg[:db],Db)
        @stat=Status.new.set_db(@adb)
        @cls_color=2
        super('app',@stat['id'],Command.new(cfg))
        @fsh=type?(cfg.layers[:frm].get(@id),Frm::Exe)
        @mode=@fsh.mode
        @site_stat=@fsh.site_stat.add_db('isu' => '*')
        @print=View.new(@adb,@stat)
        @output=$opt['j']?@stat:@print
        @batch_interrupt=[]
        ext_shell
      end

      private
      def ext_shell
        super
        @view_grp=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        @view_grp.add_item('vis',"Visual mode").set_proc{@output=@print;''}
        @view_grp.add_item('raw',"Raw Print mode").set_proc{@output=@stat;''}
        self
      end
    end

    class Test < Exe
      require "libappsym"
      def initialize(cfg)
        super
        @mode='TEST'
        @stat.ext_sym
        @stat.post_upd_procs << proc{|st|
          verbose("App","Propagate Status#upd -> App#settime")
          st['time']=now_msec
        }
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
          ent.par[0].split(',').each{|key| @stat.del(key) }
          "DELETE:#{ent.par[0]}"
        }
        @cobj.item_proc('interrupt'){|ent|
          "INTERRUPT(#{@batch_interrupt})"
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
        @stat.ext_rsp(@fsh.field).ext_sym.ext_file
        @buf=init_buf
        ver=@stat['ver']
        @fsh.flush_procs << proc{
          verbose("AppSv","Propagate Frm::Exe#flush -> Buffer#flush")
          @buf.flush
        }
        @cobj.ext_proc{|ent,src,pri|
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
        if sv=cfg[:sqlog]
          sv.add_table(@stat)
        end
        ext_server(@adb['port'])
      end

      private
      def server_output
        Hashx.new.update(@site_stat).update(self).to_j
      end

      def init_buf
        buf=Buffer.new(@stat['id'],@stat['ver'],@site_stat)
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
          verbose("AppSv","Propagate Buffer#flush -> Status#upd")
          @stat.upd
          sleep(@interval||0.1)
          # Auto issue by watch
        }
        buf.server
      end
    end

    if __FILE__ == $0
      require 'libsitedb'
      ENV['VER']||='initialize'
      GetOpts.new('chlset')
      begin
        cfg=Config.new('app')
        cfg[:db]=Site::Db.new.set(ARGV.shift)[:adb]
        puts App.new(cfg).shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
