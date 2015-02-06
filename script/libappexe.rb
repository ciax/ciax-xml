#!/usr/bin/ruby
require "libappdb"
require "libappview"
require "libappcmd"
require "libapprsp"
require "libappsym"
require 'libfrmexe'
require "libbuffer"
require "libsqlog"

module CIAX
  module App
    # site_cfg should have [:frm_list](Frm::List)
    def self.new(site_cfg)
      Msg.type?(site_cfg,Hash)
      if $opt.delete('l')
        site_cfg['host']='localhost'
        Sv.new(site_cfg)
      elsif host=$opt['h']
        site_cfg['host']=host
      elsif $opt['c']
      elsif $opt['s'] or $opt['e']
        return Sv.new(site_cfg)
      else
        return Test.new(site_cfg)
      end
      Cl.new(site_cfg)
    end

    class Exe < Exe
      # site_cfg should have 'id',:adb
      # it inherits :site_stat,:batch_interrupt from Watch layer;
      attr_reader :adb,:stat
      def initialize(site_cfg)
        @cls_color=2
        @adb=site_cfg[:db]=type?(site_cfg[:adb],Db)
        super
        @stat=@cfg[:stat]=Status.new.set_db(@adb)
        @site_stat=@cfg[:site_stat].add_db('isu' => '*')
        @appview=View.new(@adb,@stat)
        @output=$opt['j']?@stat:@appview
        @batch_interrupt=(@cfg[:batch_interrupt]||=[])
        ext_shell
      end

      private
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
      def initialize(site_cfg)
        super
        @stat.ext_sym
        @stat.post_upd_procs << proc{|st|
          verbose("App","Propagate Status#upd -> App#settime")
          st['time']=now_msec
        }
        @cobj.add_intgrp(Int)
        @cobj.set_dmy
      end
    end

    class Cl < Exe
      def initialize(site_cfg)
        super
        host=type?(site_cfg['host']||@adb['host']||'localhost',String)
        @stat.ext_http(host)
        @pre_exe_procs << proc{@stat.upd}
        ext_client(host,@adb['port'])
      end
    end

    class Sv < Exe
      def initialize(site_cfg)
        super
        @fsh=Frm.new(@cfg)
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
      require "libsitedb"
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      begin
        cfg=Site::Db.new.set(id)
        puts App.new(cfg).shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
