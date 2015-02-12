#!/usr/bin/ruby
require "libsh"
require "libappdb"
require "libappview"
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"

module CIAX
  $layers['app']=App
  module App
    def self.new(site_cfg,attr={})
      Msg.type?(site_cfg,Hash)
      if $opt.delete('l')
        attr['host']='localhost'
        Sv.new(site_cfg,attr)
      elsif host=$opt['h']
        attr['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(site_cfg,attr)
      else
        return Test.new(site_cfg,attr)
      end
      Cl.new(site_cfg,attr)
    end

    class Exe < Exe
      # site_cfg should have 'id',:adb
      attr_reader :adb,:stat,:host,:port
      attr_accessor :batch_interrupt
      def initialize(site_cfg,attr={})
        @cls_color=2
        @adb=(attr[:db]||=type?(site_cfg[:ldb][:adb],Db))
        super
        @host=type?(@cfg['host']||@adb['host']||'localhost',String)
        @port=@adb['port']
        @stat=@cfg[:stat]=Status.new.set_db(@adb)
        @site_stat.add_db('isu' => '*')
        @appview=View.new(@adb,@stat)
        @output=$opt['j']?@stat:@appview
        @batch_interrupt=[]
      end

      def ext_shell
        super
        @view_grp=@cobj.lodom.add_group('caption'=>"Change View Mode",'color' => 9)
        @view_grp.add_item('vis',"Visual mode").set_proc{@output=@appview;''}
        @view_grp.add_item('raw',"Raw Print mode").set_proc{@output=@stat;''}
        self
      end
    end

    class Test < Exe
      require "libappsym"
      def initialize(site_cfg,attr={})
        super
        @stat.ext_sym
        @stat.post_upd_procs << proc{|st|
          verbose("App","Propagate Status#upd -> App#settime")
          st['time']=now_msec
        }
        @cobj.add_intgrp(Int)
        @cobj.ext_proc{|ent|
          @stat.upd
          'ISSUED:'+ent.batch.inspect
        }
        @cobj.item_proc('interrupt'){|ent|
          "INTERRUPT(#{@batch_interrupt})"
        }
      end
    end

    class Cl < Exe
      def initialize(site_cfg,attr={})
        super
        @stat.ext_http(@host)
        @pre_exe_procs << proc{@stat.upd}
        ext_client(@host,@port)
      end
    end

    class Sv < Exe
      require "libfrmexe"
      def initialize(site_cfg,attr={})
        super
        fsite=@cfg[:ldb]['frm_site']
        @fsh=@cfg[:site_list].get("frm:#{fsite}")
        @mode=@fsh.mode
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
      require "libsitelist"
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      begin
        puts Site::List.new('app').ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
