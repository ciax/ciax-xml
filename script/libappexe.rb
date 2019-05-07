#!/usr/bin/env ruby
require 'libappcmd'
require 'libappsym'
require 'libappview'
require 'libfrmdic'
require 'libinsdb'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Exec class
    class Exe < Exe
      # atrb must have [:dbi]
      # atrb may have [:sub_dic] if Frm layer exists
      attr_accessor :batch_interrupt
      def initialize(spcfg, atrb = Hashx.new)
        super
        @cfg[:site_id] = @id
        @sv_stat = Prompt.new('site', @id)
        @batch_interrupt = []
        _init_net
        ___init_stat
        ___init_command
        _opt_mode
      end

      private

      def _ext_shell
        super.input_conv_set
        @cfg[:output] = View.new(@stat)
        @cobj.loc.add_view
        self
      end

      def ___init_stat
        dbi = _init_dbi2cfg(%i(dev_id))
        @stat = @cfg[:stat] = Status.new(dbi, ___init_sub)
      end

      # Sub methods for Initialize
      def ___init_sub
        id = @cfg[:dev_id] || return
        # LayerDB might generated in ExeDic level
        # :sub_dic is generated for stand alone (test module)
        @sub = (@cfg[:sub_dic] ||= Frm::ExeDic.new(@cfg)).get(id)
        ___init_svstat(@sub.sv_stat)
        @sub.stat
      end

      def ___init_svstat(subsvs)
        @sv_stat.db.update(subsvs.db)
        # Upper layer propagation
        subsvs.cmt_procs.append(self, "sv_stat:#{@id}", 4) do |ss|
          @sv_stat.update(ss.pick(:comerr, :ioerr)).cmt
        end
      end

      def ___init_command
        @cobj.add_rem.cfg[:def_msg] = 'ISSUED'
        @cobj.rem.add_sys
        @cobj.rem.add_int
        @cobj.rem.add_ext
        self
      end

      # Local mode
      module Local
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        # Mode Extension by Option
        def ext_local
          super
          ___init_proc_set
          ___init_proc_del
          @stat.ext_sym(@cfg[:sdb])
          self
        end

        def run
          super
          @sv_stat.ext_local.ext_file.ext_save.ext_log
          self
        end

        private

        def _ext_test
          @cobj.rem.ext.def_proc do |ent|
            @stat[:time] = now_msec
            ent.msg = ent[:batch].inspect
          end
          super
        end

        def _ext_driver
          super
          require 'libappdrv'
          extend(Driver).ext_driver
        end

        # Initiate procs
        def ___init_proc_set
          @cobj.get('set').def_proc do |ent|
            @stat[:data].repl(ent.par[0], ent.par[1])
            @stat.cmt
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
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        db = cfg[:db] = Ins::Db.new(cfg.proj)
        Exe.new(cfg, dbi: db.get(cfg.args.shift))
      end.cui
    end
  end
end
