#!/usr/bin/ruby
require 'libsh'
require 'libmcrlist'
require 'libmcrview'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < CIAX::Exe
      # cfg should have [:dev_list]
      def initialize(cfg, atrb = {})
        atrb[:db] = Db.new
        atrb[:layer_type] = 'mcr'
        super(nil, cfg, atrb)
        _init_domain_
        _init_stat_
        _init_net_
        @mode = 'MCR'
        OPT[:l] ? ext_client : ext_driver
      end

      def ext_shell
        @cfg[:output] = @stat
        extend(Shell).ext_shell
      end

      private

      # Initialize for all mode
      def _init_domain_
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
      end

      def _init_stat_
        @par = @cobj.rem.int.ext_par.par
        @stat = List.new
        @sv_stat.add_array(:list)
        @sv_stat.add_str(:sid)
        @cfg[:sv_stat] = @sv_stat
        @post_exe_procs << proc {
          (@sv_stat.get(:list) - @par.list).each { |id| @par.add(id)}
        }
      end

      def _init_net_
        @host ||= @dbi[:host]
        @port ||= (@dbi[:port] || 55_555)
      end

      # Initialize for driver
      def ext_driver
        @sv_stat.rep(:sid, '') # For server response
        _init_pre_exe_
        _init_extcmd_
        _init_intcmd_
        _init_intrpt_
        @terminate_procs << proc { @stat.clean }
        super
      end

      def _init_pre_exe_
        @pre_exe_procs << proc do
          @sv_stat.rep(:sid, '')
          @sv_stat.flush(:list, @stat.alives)
        end
      end

      # External Command Group
      def _init_extcmd_
        @cobj.rem.ext.def_proc do |ent|
          @stat.add(ent)
          'ACCEPT'
        end
      end

      # Internal Command Group
      def _init_intcmd_
        @cobj.rem.int.def_proc do|ent|
          @sv_stat.rep(:sid, ent.par[0])
          @stat.reply(ent.id) ||'NOSID'
        end
      end

      def _init_intrpt_
        @cobj.get('interrupt').def_proc do
          @stat.interrupt
          'INTERRUPT'
        end
      end

    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('cemnlrt')
      begin
        cfg = Config.new
        cfg[:jump_groups] = []
        cfg[:dev_list] = Wat::List.new(cfg).sub_list
        Man.new(cfg).ext_shell.shell
      rescue InvalidCMD
        OPT.usage('[cmd] (par)')
      rescue InvalidID
        OPT.usage('[proj] [cmd] (par)')
      end
    end
  end
end
