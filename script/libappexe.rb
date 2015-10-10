#!/usr/bin/ruby
require 'libfrmexe'
require 'libappdb'
require 'libappview'
require 'libappcmd'
require 'libapprsp'
require 'libappsym'
require 'libbuffer'
require 'libinsdb'

module CIAX
  module App
    class Exe < Exe
      # cfg must have [:db],[:sub_list]
      attr_accessor :batch_interrupt
      def initialize(id, cfg)
        super(id, cfg)
        @cfg[:site_id] = id
        # LayerDB might generated in List level
        @cfg['ver'] = @dbi['version']
        @cfg[:frm_site] = @dbi['frm_site']
        @sub = @cfg[:sub_list].get(@cfg[:frm_site])
        @sv_stat = @sub.sv_stat.add_db('isu' => '*')
        @stat = Status.new.setdbi(@dbi)
        @batch_interrupt = []
        @host ||= @dbi['host']
        @port ||= @dbi['port']
        @cobj.add_rem.add_hid
        @cobj.rem.add_ext(Ext)
        @cobj.rem.add_int(Int)
        opt_mode
      end

      def ext_shell
        super
        @cfg[:output] = View.new(@stat)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      private

      def ext_test
        @mode = 'TEST'
        @stat.ext_sym.ext_save.ext_load
        @cobj.get('interrupt').def_proc {
          "INTERRUPT(#{@batch_interrupt})"
        }
        @cobj.rem.ext.def_proc {
          @stat['time'] = now_msec
          'TEST'
        }
        ext_non_client
      end

      def ext_driver
        @mode = 'DRV'
        @stat.ext_rsp(@sub.stat).ext_sym.ext_save.ext_load
        @stat.ext_log.ext_sqlog if OPT['e']
        init_buf
        if @cfg[:exe_mode]
          tc = Thread.current
          @stat.post_upd_procs << proc { tc.run }
          @post_exe_procs << proc { sleep }
        end
        ext_non_client
      end

      def ext_non_client
        @cobj.get('set').def_proc {|ent|
          @stat.rep(ent.par[0], ent.par[1])
          "SET:#{ent.par[0]}=#{ent.par[1]}"
        }
        @cobj.get('del').def_proc {|ent|
          ent.par[0].split(',').each { |key| @stat.del(key) }
          "DELETE:#{ent.par[0]}"
        }
        self
      end

      def server_output
        Hashx.new.update(@sv_stat).update(self).to_j
      end

      def init_buf
        buf = Buffer.new(@stat['id'], @stat['ver'], @sv_stat)
        buf.recv_proc {|args, src|
          verbose { "Processing #{args}" }
          @sub.exe(args, src)
        }
        buf.post_upd_procs << proc {
          verbose { 'Propagate Buffer#upd -> Status#upd' }
          @stat.upd
        }
        @sub.stat.flush_procs << proc {
          verbose { 'Propagate Field#flush -> Buffer#upd' }
          buf.upd
        }
        @cobj.rem.ext.def_proc {|ent, src, pri|
          verbose { "#{@id}/Issuing:#{ent.id} from #{src} with priority #{pri}" }
          buf.send(ent, pri)
          'ISSUED'
        }
        @cobj.get('interrupt').def_proc {|_, src|
          @batch_interrupt.each {|args|
            verbose { "#{@id}/Issuing:#{args} for Interrupt" }
            buf.send(@cobj.set_cmd(args), 0)
          }
          warning("Interrupt(#{@batch_interrupt}) from #{src}")
          'INTERRUPT'
        }
        buf.server
      end
    end

    class List < Site::List
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self, Frm::List)
        store_db(Ins::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ENV['VER'] ||= 'initialize'
      OPT.parse('ceh:lts')
      cfg = Config.new
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
