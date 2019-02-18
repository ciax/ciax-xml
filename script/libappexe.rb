#!/usr/bin/env ruby
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
      def initialize(spcfg, atrb = Hashx.new)
        super
        dbi = _init_dbi2cfg(%i(dev_id))
        @cfg[:site_id] = @id
        @stat = Status.new(dbi)
        @sv_stat = Prompt.new('site', @id)
        @batch_interrupt = []
        _init_net
        ___init_command
        ___init_sub if @cfg[:dev_id]
        _opt_mode
      end

      private

      # Mode Extension by Option
      def _ext_local
        ___init_proc_set
        ___init_proc_del
        super
      end

      def _ext_local_shell
        super.input_conv_set
        @cfg[:output] = View.new(@stat)
        @cobj.loc.add_view
        self
      end

      def _ext_local_test
        @cobj.rem.ext.def_proc do |ent|
          @stat[:time] = now_msec
          ent.msg = ent[:batch].inspect
        end
        @stat.ext_local_sym(@cfg[:sdb])
        super
      end

      def _ext_local_driver
        super
        require 'libappdrv'
        extend(Driver).ext_local_driver
      end

      # Sub methods for Initialize
      def ___init_sub
        # LayerDB might generated in Dic level
        @sub = @cfg[:sub_dic].get(@cfg[:dev_id])
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

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg|
        db = cfg[:db] = Ins::Db.new
        dbi = db.get(cfg.args.shift)
        atrb = { dbi: dbi, sub_dic: Frm::Dic.new(cfg) }
        eobj = Exe.new(cfg, atrb)
        if cfg.opt.sh?
          eobj.shell
        else
          puts eobj.exe(cfg.args).stat
        end
      end
    end
  end
end
