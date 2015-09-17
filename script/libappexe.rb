#!/usr/bin/ruby
require "libfrmexe"
require "libappdb"
require "libappview"
require "libappcmd"
require "libapprsp"
require "libappsym"
require "libbuffer"
require "libinsdb"

module CIAX
  module App
    class Exe < Exe
      # cfg must have [:db],[:sub_list]
      attr_accessor :batch_interrupt
      def initialize(id,cfg)
        super(id,cfg)
        @cfg[:site_id]=id
        # LayerDB might generated in List level
        @cfg['ver']=@dbi['version']
        @cfg[:frm_site]=@dbi['frm_site']
        @sub=@cfg[:sub_list].get(@cfg[:frm_site])
        @site_stat=@sub.site_stat.add_db('isu' => '*')
        @stat=Status.new.set_dbi(@dbi)
        @batch_interrupt=[]
        @host||=@dbi['host']
        @port||=@dbi['port']
        @cobj.add_rem.add_hid
        @cobj.rem.add_ext(Ext)
        @cobj.rem.add_int(Int)
        opt_mode
      end

      def ext_shell
        super
        @cfg[:output]=View.new(@stat)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private
      def ext_test
        @stat.ext_sym.ext_file
        @stat.post_upd_procs << proc{|st|
          verbose("Propagate Status#upd -> App#settime")
          st['time']=now_msec
        }
        @post_exe_procs << proc{@stat.upd}
        @cobj.get('interrupt').def_proc{|ent|
          "INTERRUPT(#{@batch_interrupt})"
        }
        @cobj.rem.ext.def_proc{|ent| ent.cfg.path}
        ext_int
        super
      end

      def ext_driver
        @stat.ext_rsp(@sub.stat).ext_sym.ext_file.ext_sqlog
        @buf=init_buf
        ver=@stat['ver']
        @sub.flush_procs << proc{
          verbose("Propagate Frm::Exe#flush -> Buffer#flush")
          @buf.flush
        }
        @cobj.rem.ext.def_proc{|ent,src,pri|
          verbose("#@id/Issuing:#{ent.id} from #{src} with priority #{pri}")
          @buf.send(ent,pri)
          "ISSUED"
        }
        @cobj.get('interrupt').def_proc{|ent,src|
          @batch_interrupt.each{|args|
            verbose("#@id/Issuing:#{args} for Interrupt")
            @buf.send(@cobj.set_cmd(args),0)
          }
          warning("Interrupt(#{@batch_interrupt}) from #{src}")
          'INTERRUPT'
        }
        ext_int
        super
      end

      def ext_int
        @cobj.get('set').def_proc{|ent|
          @stat.rep(ent.par[0],ent.par[1])
          "SET:#{ent.par[0]}=#{ent.par[1]}"
        }
        @cobj.get('del').def_proc{|ent|
          ent.par[0].split(',').each{|key| @stat.del(key) }
          "DELETE:#{ent.par[0]}"
        }
        self
      end

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
          sleep(0.1)
          # Auto issue by watch
        }
        buf.server
      end
    end

    class List < Site::List
    # cfg should have [:jump_groups]
      def initialize(cfg)
        super(cfg,Frm::List.new(cfg))
        set_db(Ins::Db.new)
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('ceh:lts')
      cfg=Config.new
      cfg[:site]=ARGV.shift
      cfg[:jump_groups]=[]
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
