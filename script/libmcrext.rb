#!/usr/bin/ruby
require 'libsh'
require 'libmcrlist'

module CIAX
  module Mcr
    class Man < CIAX::Exe
      # cfg should have [:dev_list]
      def initialize(cfg, attr = {})
        attr[:db] = Db.new
        attr[:layer_type] = 'mcr'
        super(PROJ, cfg, attr)
        @sub_list = List.new
        @lastsize = 0
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.int.add_item('clean', 'Clean list')
        @cobj.rem.add_ext(Ext)
        @parameter = @cobj.rem.int.par
        @valid_keys = @sv_stat[:list] = @parameter[:list] = []
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
        @pre_exe_procs << proc do
          @valid_keys.replace @sub_list.clean.keys
          @sv_stat['sid'] = ''
        end
        # External Command Group
        @cobj.rem.ext.def_proc do |ent|
          sid = @sub_list.add(ent).id
          @sv_stat['sid'] = sid
          @valid_keys << sid if sid
          'ACCEPT'
        end
        # Internal Command Group
        @cfg[:submcr_proc] = proc do|args, pid|
          @sub_list.add(@cobj.set_cmd(args), pid)
        end
        @cobj.rem.int.def_proc do|ent|
          seq = @sub_list.get(ent.par[0])
          if seq
            @sv_stat['sid'] = seq.id
            seq.reply(ent[:id])
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
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('cmnlrt')
      begin
        cfg = Config.new
        cfg[:dev_list] = Wat::List.new(cfg).sub_list
        cfg[:jump_groups] = []
        Man.new(cfg).ext_shell.shell
      rescue InvalidCMD
        OPT.usage('[cmd] (par)')
      rescue InvalidID
        OPT.usage('[proj] [cmd] (par)')
      end
    end
  end
end
