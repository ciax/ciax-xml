#!/usr/bin/ruby
require 'libfrmexe'
require 'libappdb'
require 'libappview'
require 'libappcmd'
require 'libapprsp'
require 'libappsym'
require 'libbuffer'
require 'libinsdb'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Exec class
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
        @stat = Status.new.setdbi(@dbi)
        @batch_interrupt = []
        init_server
        init_command
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

      def init_server
        @sv_stat = @sub.sv_stat
        @host ||= @dbi['host']
        @port ||= @dbi['port']
        self
      end

      def init_command
        @cobj.add_rem.add_hid
        @cobj.rem.add_ext(Ext)
        @cobj.rem.add_int(Int)
        self
      end

      def ext_test
        @mode = 'TEST'
        @stat.ext_sym.ext_file.upd
        @cobj.get('interrupt').def_proc do
          "INTERRUPT(#{@batch_interrupt})"
        end
        @cobj.rem.ext.def_proc do
          @stat['time'] = now_msec
          'TEST'
        end
        ext_non_client
      end

      def ext_driver
        @mode = 'DRV'
        @stat.ext_rsp(@sub.stat).ext_sym.ext_file.auto_save.upd
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
        @cobj.get('set').def_proc do|ent|
          @stat.rep(ent.par[0], ent.par[1])
          "SET:#{ent.par[0]}=#{ent.par[1]}"
        end
        @cobj.get('del').def_proc do|ent|
          ent.par[0].split(',').each { |key| @stat.del(key) }
          "DELETE:#{ent.par[0]}"
        end
        self
      end

      def server_output
        Hashx.new.update(@sv_stat).update(self).to_j
      end

      # Process of command execution:
      #  Main: Recieve App command with validation
      #  Main: Set 'isu' flag in Server status
      #  Main: Send command to queue of Buffer thread (Async)
      #  Main: Send back App response with msg 'ISSUED' in Server Status
      #    Buffer: Recieve the command from queue
      #    Buffer: Break up to Frm commands (Batch)
      #    Buffer: Reorder by priority and set command to outbuffer
      #      Batch: Pick up the command from outbuffer by priority
      #      Batch: Execute single Frm command
      #      Batch: Get Frm command response
      #      Batch: Update Field by Frm response
      #      Batch: Repeat until outbuffer is empty
      def init_buf
        buf = Buffer.new(@sv_stat)
        # App: Sendign a first priority command (interrupt)
        @cobj.get('interrupt').def_proc do|_, src|
          @batch_interrupt.each do|args|
            verbose { "Issuing:#{args} for Interrupt" }
            buf.send(@cobj.set_cmd(args), 0)
          end
          warning("Interrupt(#{@batch_interrupt}) from #{src}")
          'INTERRUPT'
        end
        # App: Sending a general App command (Frm batch)
        @cobj.rem.ext.def_proc do|ent, src, pri|
          verbose { "Issuing:[#{ent.id}] from #{src} with priority #{pri}" }
          buf.send(ent, pri)
          'ISSUED'
        end
        # Frm: Execute single command
        buf.recv_proc = proc do|args, src|
          verbose { "Processing #{args}" }
          @sub.exe(args, src)
        end
        # Frm: Update after each single command finish
        # @stat file output should be done before 'isu' flag is reset
        buf.flush_proc = proc do
          verbose { 'Propagate Buffer#flush -> Field#flush' }
          @sub.stat.flush
        end
        # Field: Update after each Batch Frm command finish
        @sub.stat.flush_procs << proc do
          verbose { 'Propagate Field#flush -> Status#upd' }
          @stat.upd
        end
        # Start buffer server thread
        buf.server
      end
    end

    # Application List
    class List < Site::List
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self, Frm::List)
        store_db(Ins::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
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
