#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    class Exe < CIAX::Exe
      # cfg should have [:jump_groups]
      attr_reader :sub_list
      def initialize(cfg,attr={})
        attr[:db]=Db.new
        @sub_list=attr[:sub_list]=Wat::List.new(cfg)
        super(PROJ,cfg,attr)
        @list=List.new(@id,@cfg)
        @lastsize=0
        @cobj.add_rem.add_hid
        @cobj.rem.add_int(Int)
        @cobj.rem.int.add_item('clean','Clean list')
        @cobj.rem.add_ext(Ext)
        @parameter=@cobj.rem.int.par
        @list.post_upd_procs << proc{
          verbose("Propagate List#upd -> Parameter#upd")
          @parameter[:list]=@list.keys
        }
        #Set sublist
        @cfg['host']||=@dbi['host']
        @cfg['port']||=(@dbi['port']||5555)
        opt_mode
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      private
      def ext_test
        ext_driver
      end

      def ext_client
        @pre_exe_procs << proc{@list.upd}
        @list.ext_http
        super
      end

      def ext_driver
        @site_stat['sid']='' # For server response
        @pre_exe_procs << proc{ @site_stat['sid']='' }
        @list.ext_sv
        # External Command Group
        @cobj.rem.ext.def_proc{|ent| set(ent);"ACCEPT"}
        # Internal Command Group
        @cfg[:submcr_proc]=proc{|args,pid|
          set(@cobj.set_cmd(args),pid)
        }
        @cobj.rem.int.def_proc{|ent|
          if seq=@list.get(ent.par[0])
            @site_stat['sid']=seq.record['id']
            seq.exe(ent.id.split(':'))
            'ACCEPT'
          else
            "NOSID"
          end
        }
        @cobj.get('clean').def_proc{ @list.clean;'ACCEPT'}
        @cobj.get('interrupt').def_proc{|ent|
          @list.interrupt
          'INTERRUPT'
        }
        @terminate_procs << proc{ @list.clean}
        super
      end

      def set(ent,pid='0')
        @list.add(ent,pid)
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
        @records={nil => @list}
        self
      end

      private
      def upd_current
        @list.upd
        if @current > @list.size or @list.size > @lastsize
          set_current(@lastsize=@list.size)
        end
        msg="[%d]" % @current
        if @current > 0
          seq=@list.get(@parameter[:default])
          msg << "(#{seq['stat']})"+optlist(seq['option'])
        end
        msg
      end

      def set_current(i)
        return i.to_s if i > @list.size
        @current=i
        if i > 0
          id=@list.keys[i-1]
          @records[id]||=get_record(@list.get(id))
        end
        @parameter[:default]=id
        @cfg[:output]=@records[id]
        nil
      end

      def list_mode
        @current=0
        @cfg[:output]=@list
        @parameter[:default]=nil
        ''
      end

      def get_record(seq)
        case seq
        when Hash
          Record.new(seq['id']).ext_http
        when Seq
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
