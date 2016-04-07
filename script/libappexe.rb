#!/usr/bin/ruby
require 'libfrmlist'
require 'libbuffer'
require 'libinsdb'
require 'libappcmd'
require 'libapprsp'
require 'libappview'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Exec class
    class Exe < Exe
      # cfg must have [:dbi],[:sub_list]
      attr_accessor :batch_interrupt
      def initialize(id, cfg, atrb = Hashx.new)
        super
        dbi = _init_dbi(id, %i(frm_site))
        @cfg[:site_id] = id
        @stat = Status.new(dbi)
        @sv_stat = Prompt.new('site', id).add_flg(busy: '*')
        @batch_interrupt = []
        init_sub
        init_server(dbi)
        init_command
        _opt_mode
      end

      def ext_shell
        super
        @cfg[:output] = View.new(@stat)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      def busy?
        @sv_stat.up?(:busy)
      end

      # return nil if success
      def waiting(src = 'local', pri = 1)
        verbose { "Waiting busy for #{@id}" }
        100.times do
          exe([], src, pri)
          return true unless busy?
          sleep 0.1
        end
        false
      end

      private

      def init_sub
        # LayerDB might generated in List level
        @sub = @cfg[:sub_list].get(@cfg[:frm_site])
        @sv_stat.sub_merge(@sub.sv_stat, %i(comerr ioerr))
      end

      def init_server(dbi)
        @host = @cfg[:option].host || dbi[:host]
        @port ||= dbi[:port]
        self
      end

      def init_command
        @cobj.add_rem.add_sys
        @cobj.rem.add_ext(Ext)
        @cobj.rem.add_int(Int)
        self
      end

      def ext_test
        @stat.ext_sym.ext_file
        @cobj.get('interrupt').def_proc do |ent|
          # "INTERRUPT(#{@batch_interrupt})"
          ent.msg = 'INTERRUPT'
        end
        @cobj.rem.ext.def_proc do |ent|
          @stat[:time] = now_msec
          ent.msg = ent[:batch].inspect
        end
        ext_non_client
        super
      end

      # type of usage: shell/command line
      # type of semantics: execution/test
      def ext_driver
        @stat.ext_rsp(@sub.stat).ext_sym.ext_file.auto_save
        @buf = init_buf
        ext_exec_mode
        ext_non_client
        super
      end

      def ext_non_client
        _init_proc_set
        _init_proc_del
        self
      end

      def ext_exec_mode
        return unless @cfg[:option].log?
        @stat.ext_log.ext_sqlog
        @cobj.rem.ext_log('app')
      end

      def server_output
        Hashx.new.update(@sv_stat).update(self).to_j
      end

      # Process of command execution:
      #  Main: Recieve App command with validation
      #  Main: Set :busy flag in Server status
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
        _init_proc_int(buf)
        _init_proc_ext(buf)
        _init_proc_buf(buf)
        _init_proc_sub
        # Start buffer server thread
        buf.server
      end

      # Initialize procs
      def _init_proc_set
        @cobj.get('set').def_proc do|ent|
          @stat[:data].repl(ent.par[0], ent.par[1])
          # "SET:#{ent.par[0]}=#{ent.par[1]}"
          ent.msg = 'ISSUED'
        end
      end

      def _init_proc_del
        @cobj.get('del').def_proc do|ent|
          ent.par[0].split(',').each { |key| @stat[:data].delete(key) }
          # "DELETE:#{ent.par[0]}"
          ent.msg = 'ISSUED'
        end
      end

      # App: Sendign a first priority command (interrupt)
      def _init_proc_int(buf)
        @cobj.get('interrupt').def_proc do |ent, src|
          @batch_interrupt.each do|args|
            verbose { "Issuing:#{args} for Interrupt" }
            buf.send(@cobj.set_cmd(args), 0)
          end
          warning("Interrupt(#{@batch_interrupt}) from #{src}")
          ent.msg = 'INTERRUPT'
        end
      end

      # App: Sending a general App command (Frm batch)
      def _init_proc_ext(buf)
        @cobj.rem.ext.def_proc do|ent, src, pri|
          verbose { "Issuing:[#{ent.id}] from #{src} with priority #{pri}" }
          buf.send(ent, pri)
          ent.msg = 'ISSUED'
        end
      end

      def _init_proc_buf(buf)
        # Frm: Execute single command
        buf.recv_proc = proc do|args, src|
          verbose { "Processing #{args}" }
          @sub.exe(args, src)
        end
        # Frm: Update after each single command finish
        # @stat file output should be done before :busy flag is reset
        buf.flush_proc = proc do
          verbose { 'Propagate Buffer#flush -> Field#flush' }
          @sub.stat.flush
        end
      end

      # Field: Update after each Batch Frm command finish
      def _init_proc_sub
        @sub.stat.flush_procs << proc do
          verbose { 'Propagate Field#flush -> Status#upd' }
          @stat.upd
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        atrb = { db: Ins::Db.new, sub_list: Frm::List.new(cfg) }
        Exe.new(args.shift, cfg, atrb).ext_shell.shell
      end
    end
  end
end
