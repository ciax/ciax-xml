#!/usr/bin/ruby
require 'libappdrv'
require 'libapprsp'
require 'libappview'
require 'libfrmlist'
require 'libinsdb'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Exec class
    class Exe < Exe
      # cfg must have [:dbi],[:sub_list]
      attr_accessor :batch_interrupt
      def initialize(cfg, atrb = Hashx.new)
        super
        dbi = _init_with_dbi(%i(frm_site))
        @cfg[:site_id] = id
        @stat = Status.new(dbi)
        @sv_stat = Prompt.new(id)
        @batch_interrupt = []
        _init_sub_
        _init_net(dbi)
        _init_command
        _opt_mode
      end

      def exe(args, src = nil, pri = 1)
        super
      end

      def ext_shell
        super
        @cfg[:output] = View.new(@stat)
        @cobj.loc.add_view
        input_conv_set
        self
      end

      def active?
        @sv_stat.upd.up?(:event)
      end

      # wait for busy end or status changed
      def wait_ready
        verbose { "Waiting busy end for #{@id}" }
        100.times do
          sleep 0.1
          next if @sv_stat.upd.up?(:busy)
          return true unless @sv_stat.up?(:comerr)
          com_err('Device not responding')
        end
        false
      end

      private

      # Initialize subroutine
      def _init_sub_
        # LayerDB might generated in List level
        @sub = @cfg[:sub_list].get(@cfg[:frm_site])
        @sv_stat.db.update(@sub.sv_stat.db)
        @sub.sv_stat.cmt_procs << proc do |ss|
          @sv_stat.update(ss.pick(%i(comerr ioerr))).cmt
        end
      end

      def _init_net(dbi)
        @host = @cfg[:opt].host || dbi[:host]
        @port ||= dbi[:port]
        self
      end

      def _init_command
        @cobj.add_rem.cfg[:def_msg] = 'ISSUED'
        @cobj.rem.add_sys
        @cobj.rem.add_int
        @cobj.rem.add_ext
        self
      end

      # Mode Extension
      def ext_local_test
        @stat.ext_local_sym.ext_local_file
        @cobj.rem.ext.def_proc do |ent|
          @stat[:time] = now_msec
          ent.msg = ent[:batch].inspect
        end
        super
      end

      def ext_local_driver
        super
        extend(Drv).ext_local_driver
      end

      def ext_local
        _init_proc_set_
        _init_proc_del_
        super
      end

      # Initiate procs
      def _init_proc_set_
        @cobj.get('set').def_proc do |ent|
          @stat[:data].repl(ent.par[0], ent.par[1])
          verbose { "SET:#{ent.par[0]}=#{ent.par[1]}" }
        end
      end

      def _init_proc_del_
        @cobj.get('del').def_proc do |ent|
          ent.par[0].split(',').each { |key| @stat[:data].delete(key) }
          verbose { "DELETE:#{ent.par[0]}" }
        end
      end
    end

    # For App
    class Prompt < Prompt
      def initialize(id)
        super('site', id)
        init_flg(busy: '*')
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        dbi = Ins::Db.new.get(args.shift)
        atrb = { dbi: dbi, sub_list: Frm::List.new(cfg) }
        Exe.new(cfg, atrb).ext_shell.shell
      end
    end
  end
end
