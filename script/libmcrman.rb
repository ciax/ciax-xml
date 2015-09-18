#!/usr/bin/ruby
require "libsh"
require "libseqlist"

module CIAX
  module Mcr
    module Man
      class Exe < CIAX::Exe
        # cfg should have [:jump_groups]
        attr_reader :sub_list
        def initialize(cfg)
          @sub_list=Wat::List.new(cfg)
          super(PROJ,cfg,{:db =>Db.new,:sub_list =>@sub_list.sub_list})
          @stat=Seq::List.new(@id,@cfg)
          @lastsize=0
          @cobj.add_rem.add_hid
          @cobj.rem.add_int(Int)
          @cobj.rem.int.add_item('clean','Clean list')
          @cobj.rem.add_ext(Ext)
          @parameter=@cobj.rem.int.par
          @stat.post_upd_procs << proc{
            verbose("Propagate List#upd -> Parameter#upd")
            @parameter[:list]=@stat.keys
          }
          @host||=@dbi['host']
          @port||=(@dbi['port']||5555)
          @mode='MCR'
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
          @site_stat['sid']='' # For server response
          @pre_exe_procs << proc{ @site_stat['sid']='' }
          @stat.ext_sv
          # External Command Group
          @cobj.rem.ext.def_proc{|ent| set(ent);"ACCEPT"}
          # Internal Command Group
          @cfg[:submcr_proc]=proc{|args,pid|
            set(@cobj.set_cmd(args),pid)
          }
          @cobj.rem.int.def_proc{|ent|
            if seq=@stat.get(ent.par[0])
              @site_stat['sid']=seq.record['id']
              seq.exe(ent.id.split(':'))
              'ACCEPT'
            else
              "NOSID"
            end
          }
          @cobj.get('clean').def_proc{ @stat.clean;'ACCEPT'}
          @cobj.get('interrupt').def_proc{|ent|
            @stat.interrupt
            'INTERRUPT'
          }
          @terminate_procs << proc{ @stat.clean}
          super
        end

        def set(ent,pid='0')
          @stat.add(ent,pid)
        end
      end

      module Shell
        include CIAX::Shell
        def ext_shell
          super
          list_mode
          @prompt_proc=proc{upd_current}
          # Convert as command
          input_conv_num{|i|
            set_current(i)
          }
          # Convert as parameter
          input_conv_num(@cobj.rem.int.keys){|i|
            set_current(i)
          }
          @post_exe_procs << proc{@cfg[:output].upd}
          vg=@cobj.loc.add_view
          vg.add_item("list","List mode").def_proc{list_mode}
          vg.add_dummy("[1-n]","Sequencer mode")
          @records={nil => @stat}
          self
        end

        private
        def upd_current
          @stat.upd
          if @current > @stat.size or @stat.size > @lastsize
            set_current(@lastsize=@stat.size)
          end
          msg="[%d]" % @current
          if @current > 0
            seq=@stat.get(@parameter[:default])
            msg << "(#{seq['stat']})"+optlist(seq['option'])
          end
          msg
        end

        def set_current(i)
          return i.to_s if i > @stat.size
          @current=i
          if i > 0
            id=@stat.keys[i-1]
            @records[id]||=get_record(@stat.get(id))
          end
          @parameter[:default]=id
          @cfg[:output]=@records[id]
          nil
        end

        def list_mode
          @current=0
          @cfg[:output]=@stat
          @parameter[:default]=nil
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

      if __FILE__ == $0
        ENV['VER']||='initialize'
        GetOpts.new('cmnlrt')
        begin
          cfg=Config.new
          cfg[:jump_groups]=[]
          Exe.new(cfg).ext_shell.shell
        rescue InvalidCMD
          $opt.usage("[mcr] [cmd] (par)")
        end
      end
    end
  end
end
