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
      def initialize(cfg)
        super(nil, Conf.new(cfg))
        verbose { 'Initialize Layer' }
        # id = nil -> taken by ARGV
        _init_net_
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

      # Initialize for driver
      def ext_driver
        @sv_stat.repl(:sid, '') # For server response
        _init_proc_pre_exe_
        _init_proc_extcmd_
        _init_proc_intcmd_
        _init_proc_intrpt_
        _init_proc_swmode_
        @terminate_procs << proc { @stat.clean }
        super
      end

      alias_method :ext_test, :ext_driver

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
        @sv_stat = @cfg[:sv_stat]
        @sub_list = @cfg[:dev_list]
        _init_proc_post_exe_
      end

      def _init_net_
        @id = @cfg[:id]
        @host = @cfg[:host]
        @port = @cfg[:port]
      end

      def _init_proc_pre_exe_
        @pre_exe_procs << proc do
          @sv_stat.repl(:sid, '')
          @sv_stat.flush(:list, @stat.alives)
        end
      end

      def _init_proc_post_exe_
        @post_exe_procs << proc do
          (@sv_stat.get(:list) - @par.list).each { |id| @par.add(id) }
        end
      end

      # External Command Group
      def _init_proc_extcmd_
        @cobj.rem.ext.def_proc do |ent|
          sid = @stat.add(ent).id
          @sv_stat.repl(:sid, sid)
          @sv_stat.push(:list, sid)
          ent.msg = 'ACCEPT'
        end
      end

      # Internal Command Group
      def _init_proc_intcmd_
        @cobj.rem.int.def_proc do|ent|
          @sv_stat.repl(:sid, ent.par[0])
          ent.msg = @stat.reply(ent.id) || 'NOSID'
        end
      end

      def _init_proc_intrpt_
        @cobj.get('interrupt').def_proc do |ent|
          @stat.interrupt
          ent.msg = 'INTERRUPT'
        end
      end

      def _init_proc_swmode_
        @cobj.get('nonstop').def_proc do
          @sv_stat.up(:nonstop)
        end
        @cobj.get('interactive').def_proc do
          @sv_stat.dw(:nonstop)
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', 'cenlrs') do |cfg|
        Man.new(cfg).ext_shell.shell
      end
    end
  end
end
