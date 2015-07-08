#!/usr/bin/ruby
require "libfrmexe"
require "libappdb"
require "libappview"
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libsqlog"
require "libinsdb"

module CIAX
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
      # cfg must have [:db],[:frm_list]
      attr_reader :adb,:stat,:host,:port
      attr_accessor :batch_interrupt
      def initialize(id,cfg={},attr={})
        super
        @cfg[:site_id]=id
        # LayerDB might generated in List level
        @adb=type?(@cfg[:db].get(id),Dbi)
        @cfg['ver']=@adb['version']
        @cfg[:frm_site]=@adb['frm_site']
        @sub=@cfg[:sub_list].get(@cfg[:frm_site])
        @site_stat=@sub.site_stat.add_db('isu' => '*')
        @stat=@cfg[:stat]=Status.new.set_db(@adb)
        @appview=View.new(@adb,@stat)
        @batch_interrupt=[]
        @cfg['host']||=@adb['host']
        @cfg['port']||=@adb['port']
        @cobj=Index.new(@cfg)
        @cobj.add_rem.add_hid
        @cobj.rem.add_ext(@adb)
      end

      def ext_shell
        super
        @output=$opt['j'] ? @stat : @appview
        vg=@cobj.loc.add_view
        vg.get_item('vis').proc{@output=@appview;''}
        vg.get_item('raw').proc{@output=@stat;''}
        self
      end
    end

    class Test < Exe
      def initialize(id,cfg={},attr={})
        super
        @stat.ext_sym
        @stat.post_upd_procs << proc{|st|
          verbose("Propagate Status#upd -> App#settime")
          st['time']=now_msec
        }
        @post_exe_procs << proc{@stat.upd}
        @cobj.rem.add_int
        @cobj.get_item('interrupt').proc{|ent|
          "INTERRUPT(#{@batch_interrupt})"
        }
        @cobj.rem.ext.proc{|ent| ent.cfg.path}
      end
    end

    class Cl < Exe
      def initialize(id,cfg={},attr={})
        super
        @stat.ext_http(host)
        @pre_exe_procs << proc{@stat.upd}
        ext_client
      end
    end

    class Sv < Exe
      # cfg(attr) must have layers[:frm]
      def initialize(id,cfg={},attr={})
        super
        @stat.ext_rsp(@sub.field).ext_sym.ext_file
        @buf=init_buf
        ver=@stat['ver']
        @sub.flush_procs << proc{
          verbose("Propagate Frm::Exe#flush -> Buffer#flush")
          @buf.flush
        }
        @cobj.rem.ext.proc{|ent,src,pri|
          verbose("#@id/Issuing:#{ent.id} from #{src} with priority #{pri}")
          @buf.send(pri,ent,src)
          "ISSUED"
        }
        @cobj.get_item('interrupt').proc{|ent,src|
          @batch_interrupt.each{|args|
            verbose("#@id/Issuing:#{args} for Interrupt")
            @buf.send(0,@cobj.set_cmd(args),src)
          }
          warning("Interrupt(#{@batch_interrupt}) from #{src}")
          'INTERRUPT'
        }
        # Logging if version number exists
        if sv=@cfg[:sqlog]
          sv.add_table(@stat)
        end
      end

      private
      def server_output
        Hashx.new.update(@site_stat).update(self).to_j
      end

      def init_buf
        buf=Buffer.new(@stat['id'],@stat['ver'],@site_stat)
        buf.send_proc{|ent|
          batch=type?(ent.cfg[:batch],Array)
          verbose("Send FrmCmds #{batch}")
          batch
        }
        buf.recv_proc{|args,src|
          verbose("Processing #{args}")
          @sub.exe(args,src)
        }
        buf.flush_proc{
          verbose("Propagate Buffer#flush -> Status#upd")
          @stat.upd
          sleep(@interval||0.1)
          # Auto issue by watch
        }
        buf.server
      end
    end

    class List < Site::List
      def initialize(cfg,attr={})
        super
        set_db(Ins::Db.new) unless @cfg[:db]
        @cfg[:sub_list]=sub_list(Frm)
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('celts')
      id=ARGV.shift
      cfg=Config.new
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell(id)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
