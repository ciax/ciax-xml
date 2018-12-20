#!/usr/bin/ruby
require 'libappcmd'
require 'libstatusconv'
require 'libappview'
require 'libfrmdic'
require 'libinsdb'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Exec class
    class Exe < Exe
      # atrb must have [:dbi],[:sub_dic]
      attr_accessor :batch_interrupt
      def initialize(super_cfg, atrb = Hashx.new)
        super
        dbi = _init_dbi2cfg(%i(frm_site))
        @cfg[:site_id] = @id
        @stat = Status.new(dbi)
        @sv_stat = Prompt.new(@id)
        @batch_interrupt = []
        _init_net
        ___init_sub
        ___init_command
        _opt_mode
      end

      private

      # Mode Extension by Option
      def _ext_local
        @stat.ext_local_sym(@cfg[:sdb]).ext_local_file.auto_load
        ___init_proc_set
        ___init_proc_del
        super
      end

      def _ext_local_shell
        super.input_conv_set
        @cfg[:output] = View.new(@stat).upd
        @cobj.loc.add_view
        self
      end

      def _ext_local_test
        @cobj.rem.ext.def_proc do |ent|
          @stat[:time] = now_msec
          ent.msg = ent[:batch].inspect
        end
        super
      end

      def _ext_local_driver
        require 'libappdrv'
        extend(Driver).ext_local_driver
        super
      end

      # Sub methods for Initialize
      def ___init_sub
        # LayerDB might generated in Dic level
        @sub = @cfg[:sub_dic].get(@cfg[:frm_site])
        @sv_stat.db.update(@sub.sv_stat.db)
        @sub.sv_stat.cmt_procs << proc do |ss|
          @sv_stat.update(ss.pick(%i(comerr ioerr))).cmt
        end
      end

      def ___init_command
        @cobj.add_rem.cfg[:def_msg] = 'ISSUED'
        @cobj.rem.add_sys
        @cobj.rem.add_int
        @cobj.rem.add_ext
        self
      end

      # Initiate procs
      def ___init_proc_set
        @cobj.get('set').def_proc do |ent|
          @stat[:data].repl(ent.par[0], ent.par[1])
          verbose { "SET:#{ent.par[0]}=#{ent.par[1]}" }
        end
      end

      def ___init_proc_del
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
        atrb = { dbi: dbi, sub_dic: Frm::Dic.new(cfg) }
        eobj = Exe.new(cfg, atrb).exe(args)
        puts eobj.stat
        sleep 0.5
        puts eobj.sv_stat.to_r
      end
    end
  end
end
