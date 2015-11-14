#!/usr/bin/ruby
require 'libsh'
require 'libmcrlist'
require 'libmcrview'

module CIAX
  module Mcr
    class Man < CIAX::Exe
      # cfg should have [:dev_list]
      def initialize(cfg, attr = {})
        attr[:db] = Db.new
        attr[:layer_type] = 'mcr'
        super(nil, cfg, attr)
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
        @parameter = @cobj.rem.int.par
        @valid_keys = @sv_stat[:list] = @parameter[:list] = []
        @host ||= @dbi['host']
        @port ||= (@dbi['port'] || 55_555)
        @mode = 'MCR'
        opt_mode
      end

      def ext_shell
        @view = @cfg[:output] = View.new(@id,@valid_keys)
        @post_exe_procs << proc { @view.upd }
        extend(Shell).ext_shell
      end

      private

      def ext_test
        ext_driver
      end

      def ext_driver
        @sub_list = List.new
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
        @cobj.rem.int.def_proc do|ent|
          seq = @sub_list.get(ent.par[0])
          if seq
            @sv_stat['sid'] = seq.id
            seq.reply(ent[:id])
          else
            'NOSID'
          end
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
