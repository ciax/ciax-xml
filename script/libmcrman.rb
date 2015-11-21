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
        _init_cmd_
        @par = @cobj.rem.int.par
        @sv_stat[:list] = @par.list
        _init_net_
        @mode = 'MCR'
        opt_mode
      end

      def ext_shell
        @view = @cfg[:output] = View.new(@id, @par, @records)
        @post_exe_procs << proc { @view.upd }
        extend(Shell).ext_shell
      end

      private

      def ext_test
        ext_driver
      end

      def ext_driver
        @sub_list = List.new do |sid|
          @sv_stat['sid'] = sid
          @par.add(sid) if sid
        end
        @records = @sub_list.records
        @sv_stat['sid'] = '' # For server response
        _init_pre_exe_
        _init_extcmd_
        _init_intcmd_
        _init_intrpt_
        @terminate_procs << proc { @sub_list.clean }
        super
      end

      def _init_cmd_
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
      end

      def _init_pre_exe_
        @pre_exe_procs << proc do
          @par.flush(@sub_list.keys)
          @sv_stat['sid'] = ''
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
          seq = @sub_list.get(ent.par[0])
          if seq
            @sv_stat['sid'] = seq.id
            seq.reply(ent[:id])
          else
            'NOSID'
          end
        end
      end

      def _init_intrpt_
        @cobj.get('interrupt').def_proc do
          @sub_list.interrupt
          'INTERRUPT'
        end
      end

      def _init_net_
        @host ||= @dbi['host']
        @port ||= (@dbi['port'] || 55_555)
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
