#!/usr/bin/env ruby
require 'libexelocal'
require 'libmcrcmd'
require 'libmcrconf'
require 'librecord'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Executor
    # Local mode only
    class Exe < Exe
      def initialize(spcfg, atrb = Hashx.new, &submcr_proc)
        super
        verbose { 'Initiate New Macro' }
        ___init_cmd
        @sv_stat = type?(@cfg[:sv_stat], Prompt)
        @stat = Record.new
        _opt_mode
      end

      def interrupt
        exe(['interrupt'], 'local', 0)
        self
      end

      private

      def _ext_remote
        extend(Remote).ext_remote
      end

      # Mode Extention by Option
      def _ext_shell
        super
        @prompt_proc = proc { opt_listing(@valid_keys) }
        @cobj.loc.add_view
        @cobj.rem.add_sys
        self
      end

      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        @int = rem.add_int
        @valid_keys = @cfg[:valid_keys] = @int.valid_keys.clear
      end

      # To inhelit CIAX::Exe::Local
      module Local
        require 'libmcrdrv'
        include CIAX::Exe::Local
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def opt_mode
          super
          extend(Driver).ext_driver
        end
      end

      # Remote mode
      module Remote
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_remote
          @mode = 'CL'
          _init_port
          _remote_sv_stat
          ___init_stat
          self
        end

        private

        def ___init_stat
          sid = @sv_stat.send(@cfg[:cid]).get(:sid)
          @stat = Record.new(sid).ext_remote(@host)
          @stat.upd_procs.append(self, 'remote') do
            @valid_keys.replace(@stat[:option].to_a)
          end
          @int.pars.add_num(sid)
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Conf.new('[proj] [cmd] (par)', options: 'chedlnr') do |cfg|
        atrb = { dev_dic: cfg.opt.top_layer::ExeDic.new(cfg) }
        ent = Index.new(cfg, atrb).add_rem.add_ext.set_cmd(cfg.args)
        Exe.new(ent)
      end.cui
    end
  end
end
