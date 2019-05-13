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
        # generate @id
        _dbi_pick(:dev_id)
        @cfg[:site_id] = @id
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
        @sv_stat = Prompt.new(@id)
        @stat = @cfg[:stat] = Status.new(@dbi, ___init_field)
        @stat.stat_dic['sv_stat'] = @sv_stat
      end

      # Sub methods for Initialize
      def ___init_field
        id = @cfg[:dev_id] || return
        # LayerDB might generated in ExeDic level
        # :sub_dic is generated for stand alone (test module)
        @sub_exe = (@cfg[:sub_dic] ||= Frm::ExeDic.new(@cfg)).get(id)
        @sv_stat.sub_merge(@sub_exe.sv_stat, %i(commerr ioerr))
        @sub_exe.stat
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
          @cobj.get('set').def_proc do |ent, src|
            @stat.repl(ent.par[0], ent.par[1])
            @stat.cmt if src != 'event'
            verbose { "SET:#{ent.par[0]}=#{ent.par[1]}" }
          end
        end

        def ___init_proc_del
          @cobj.get('del').def_proc do |ent|
            ent.par[0].split(',').each { |key| @stat.delete(key) }
            verbose { "DELETE:#{ent.par[0]}" }
          end
        end
      end
    end

    # To distinct from other(dev) proc array title
    class Prompt < Prompt
      def initialize(id)
        super('site', id)
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
