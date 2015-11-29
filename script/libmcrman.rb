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
        _init_sv_stat_
        _init_net_
        @stat = Records.new
        @mode = 'MCR'
        OPT[:l] ? ext_client : ext_driver
      end

      def ext_shell
        @cfg[:output] = @stat
        extend(Shell).ext_shell
      end

      private

      def ext_driver
        @sv_stat[:sid] = '' # For server response
        _init_sub_list_
        _init_extcmd_
        _init_intcmd_
        _init_intrpt_
        @terminate_procs << proc { @sub_list.clean }
        super
      end

      def _init_sv_stat_
        @par = @cobj.rem.int.ext_par.par
        @sv_stat[:list] = @par.list
        @cfg[:sv_stat] = @sv_stat
      end

      def _init_domain_
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
      end

      def _init_sub_list_
        @sub_list = List.new(@par,@stat)
        @stat = @sub_list.records
        @pre_exe_procs << proc do
          @sv_stat[:sid] = ''
        end
      end

      # External Command Group
      def _init_extcmd_
        @cobj.rem.ext.def_proc do |ent|
          @sub_list.add(ent)
          'ACCEPT'
        end
      end

      # Internal Command Group
      def _init_intcmd_
        @cobj.rem.int.def_proc do|ent|
          @sv_stat[:sid] = ent.par[0]
          @sub_list.reply(ent.id) ||'NOSID'
        end
      end

      def _init_intrpt_
        @cobj.get('interrupt').def_proc do
          @sub_list.interrupt
          'INTERRUPT'
        end
      end

      def _init_net_
        @host ||= @dbi[:host]
        @port ||= (@dbi[:port] || 55_555)
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
