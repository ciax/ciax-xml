#!/usr/bin/ruby
require 'libfrmlist'
require 'libinsdb'
require 'libappdrv'
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
        _init_sub
        _init_net(dbi)
        _init_command
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
        @sv_stat.upd.up?(:busy)
      end

      # return nil if success
      def waiting
        verbose { "Waiting busy for #{@id}" }
        100.times do
          return true unless busy?
          sleep 0.1
        end
        false
      end

      private

      def _init_sub
        # LayerDB might generated in List level
        @sub = @cfg[:sub_list].get(@cfg[:frm_site])
        @sv_stat.sub_merge(@sub.sv_stat, %i(comerr ioerr))
      end

      def _init_net(dbi)
        @host = @cfg[:option].host || dbi[:host]
        @port ||= dbi[:port]
        self
      end

      def _init_command
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
        super
      end

      def ext_driver
        super
        extend(Drv).ext_driver
      end

      def _non_client
        _init_proc_set
        _init_proc_del
        super
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
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        atrb = { db: Ins::Db.new, sub_list: Frm::List.new(cfg) }
        Exe.new(args.shift, cfg, atrb).ext_shell.shell
      end
    end
  end
end
