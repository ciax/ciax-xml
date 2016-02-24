#!/usr/bin/ruby
require 'libsh'
require 'libmcrlist'
require 'libmcrview'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      # cfg should have [:dev_list]
      def initialize(cfg, atrb = {})
        _init_atrb_(cfg, atrb)
        super(nil, cfg, atrb)
        verbose { 'Initialize Layer' }
        # id = nil -> taken by ARGV
        _init_net_(_init_dbi(nil, [:sites]))
        _init_prompt
        @sub_list = @cfg[:dev_list]
        _init_domain_
        _init_stat_
        _opt_mode
        @mode = 'MCR:' + @mode
      end

      def ext_shell
        @cfg[:output] = @stat
        extend(Shell).ext_shell
      end

      private

      def _init_atrb_(cfg, atrb)
        atrb[:dev_list] ||= Wat::List.new(cfg)
        atrb[:db] = Db.new
        atrb[:layer_type] = 'mcr'
      end

      # Initialize for all mode
      def _init_domain_
        @cobj.add_rem.add_sys
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
        @cobj.rem.sys.add_item('nonstop', 'Mode')
        @cobj.rem.sys.add_item('interactive', 'Mode')
      end

      def _init_stat_
        @par = @cobj.rem.int.ext_par.par
        @stat = List.new
        _init_prompt_
        @post_exe_procs << proc do
          (@sv_stat.get(:list) - @par.list).each { |id| @par.add(id) }
        end
      end

      def _init_prompt_
        @sv_stat.add_array(:list)
        @sv_stat.add_array(:run)
        @sv_stat.add_str(:sid)
        @sv_stat.add_flg(nonstop: '(nonstop)')
      end

      def _init_net_(dbi)
        @host = @cfg[:option].host || dbi[:host]
        @port ||= (dbi[:port] || 55_555)
      end

      # Initialize for driver
      def ext_driver
        @sv_stat.rep(:sid, '') # For server response
        _init_pre_exe_
        _init_extcmd_
        _init_intcmd_
        _init_intrpt_
        _init_swmode_
        @terminate_procs << proc { @stat.clean }
        super
      end

      alias_method :ext_test, :ext_driver

      def _init_pre_exe_
        @pre_exe_procs << proc do
          @sv_stat.rep(:sid, '')
          @sv_stat.flush(:list, @stat.alives)
        end
      end

      # External Command Group
      def _init_extcmd_
        @cobj.rem.ext.def_proc do |ent|
          @sv_stat.push(:list, @stat.add(ent).id)
          'ACCEPT'
        end
      end

      # Internal Command Group
      def _init_intcmd_
        @cobj.rem.int.def_proc do|ent|
          @sv_stat.rep(:sid, ent.par[0])
          @stat.reply(ent.id) || 'NOSID'
        end
      end

      def _init_intrpt_
        @cobj.get('interrupt').def_proc do
          @stat.interrupt
          'INTERRUPT'
        end
      end

      def _init_swmode_
        @cobj.get('nonstop').def_proc do
          @sv_stat.up(:nonstop)
          ''
        end
        @cobj.get('interactive').def_proc do
          @sv_stat.dw(:nonstop)
          ''
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new('cenlrts')
      begin
        cfg = Config.new(option: opt)
        Man.new(cfg).ext_shell.shell
      rescue InvalidCMD
        opt.usage('[cmd] (par)')
      rescue InvalidID
        opt.usage('[proj] [cmd] (par)')
      end
    end
  end
end
