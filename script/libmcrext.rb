#!/usr/bin/ruby
require 'libsh'
require 'libmcrlist'

module CIAX
  module Mcr
    class Exe < CIAX::Exe
      # cfg should have [:dev_list]
      def initialize(cfg, attr = {})
        attr[:db] = Db.new
        attr[:layer_type] = 'mcr'
        super(PROJ, cfg, attr)
        @sub_list = List.new(@id, @cfg)
        @lastsize = 0
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.int.add_item('clean', 'Clean list')
        @cobj.rem.add_ext(Ext)
        @parameter = @cobj.rem.int.par
        @sub_list.post_upd_procs << proc do
          verbose { 'Propagate List#upd -> Parameter#upd' }
          @sv_stat[:list] = @parameter[:list] = @sub_list.keys
        end
        @host ||= @dbi['host']
        @port ||= (@dbi['port'] || 55_555)
        @mode = 'MCR'
        opt_mode
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      private

      def ext_test
        ext_driver
      end

      def ext_driver
        @sv_stat['sid'] = '' # For server response
        @pre_exe_procs << proc { @sv_stat['sid'] = '' }
        @sub_list.ext_drv
        # External Command Group
        @cobj.rem.ext.def_proc do |ent|
          @sv_stat['sid'] = add(ent).record['id']
          'ACCEPT'
        end
        # Internal Command Group
        @cfg[:submcr_proc] = proc do|args, pid|
          add(@cobj.set_cmd(args), pid)
        end
        @cobj.rem.int.def_proc do|ent|
          seq = @sub_list.get(ent.par[0])
          if seq
            @sv_stat['sid'] = seq.record['id']
            seq.exe(ent.id.split(':'))
            'ACCEPT'
          else
            'NOSID'
          end
        end
        @cobj.get('clean').def_proc do
          @sub_list.clean
          'ACCEPT'
        end
        @cobj.get('interrupt').def_proc do
          @sub_list.interrupt
          'INTERRUPT'
        end
        @terminate_procs << proc { @sub_list.clean }
        super
      end

      def add(ent, pid = '0')
        @sub_list.add(ent, pid)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('cmnlrt')
      begin
        cfg = Config.new
        cfg[:dev_list] = Wat::List.new(cfg).sub_list
        Exe.new(cfg).ext_shell.shell
      rescue InvalidCMD
        OPT.usage('[cmd] (par)')
      rescue InvalidID
        OPT.usage('[proj] [cmd] (par)')
      end
    end
  end
end
