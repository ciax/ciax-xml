#!/usr/bin/ruby
require 'libsh'
require 'libseqlist'

module CIAX
  module Mcr
    module Man
      class Exe < CIAX::Exe
        # cfg should have [:dev_list]
        def initialize(cfg, attr = {})
          attr[:db] = Db.new
          attr[:layer_type] = 'mcr'
          super(PROJ, cfg, attr)
          @stat = Seq::List.new(@id, @cfg)
          @lastsize = 0
          @cobj.add_rem.add_hid
          @cobj.rem.add_int(Int)
          @cobj.rem.int.add_item('clean', 'Clean list')
          @cobj.rem.add_ext(Ext)
          @parameter = @cobj.rem.int.par
          @stat.post_upd_procs << proc do
            verbose { 'Propagate List#upd -> Parameter#upd' }
            @parameter[:list] = @stat.keys
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
          @stat.ext_drv
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
            seq = @stat.get(ent.par[0])
            if seq
              @sv_stat['sid'] = seq.record['id']
              seq.exe(ent.id.split(':'))
              'ACCEPT'
            else
              'NOSID'
            end
          end
          @cobj.get('clean').def_proc do
            @stat.clean
            'ACCEPT'
          end
          @cobj.get('interrupt').def_proc do
            @stat.interrupt
            'INTERRUPT'
          end
          @terminate_procs << proc { @stat.clean }
          super
        end

        def add(ent, pid = '0')
          @stat.add(ent, pid)
        end
      end

      module Shell
        include CIAX::Shell
        def ext_shell
          super
          list_mode
          @prompt_proc = proc { upd_current }
          # Convert as command
          input_conv_num do|i|
            store_current(i)
          end
          # Convert as parameter
          input_conv_num(@cobj.rem.int.keys) do|i|
            store_current(i)
          end
          @post_exe_procs << proc { @cfg[:output].upd }
          vg = @cobj.loc.add_view
          vg.add_item('list', 'List mode').def_proc { list_mode }
          vg.add_dummy('[1-n]', 'Sequencer mode')
          @records = { nil => @stat }
          self
        end

        private

        def upd_current
          @stat.upd
          if @current > @stat.size || @stat.size > @lastsize
            store_current(@lastsize = @stat.size)
          end
          msg = format('[%d]', @current)
          if @current > 0
            seq = @stat.get(@parameter[:default])
            msg << "(#{seq['stat']})" + optlist(seq['option'])
          end
          msg
        end

        def store_current(i)
          return i.to_s if i > @stat.size
          @current = i
          if i > 0
            id = @stat.keys[i - 1]
            @records[id] ||= get_record(@stat.get(id))
          end
          @parameter[:default] = id
          @cfg[:output] = @records[id]
          nil
        end

        def list_mode
          @current = 0
          @cfg[:output] = @stat
          @parameter[:default] = nil
          ''
        end

        def get_record(seq)
          case seq
          when Hash
            Record.new(seq['id']).ext_http
          when Seq::Exe
            seq.record
          end
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
end
