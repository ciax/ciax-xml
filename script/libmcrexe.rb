#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    def self.new(cfg,attr={})
      if $opt.cl?
        Sv.new(cfg,attr).ext_server.server if $opt['l']
        Cl.new(cfg,attr.update($opt.host))
      else
        Sv.new(cfg,attr)
      end
    end

    class Exe < CIAX::Exe
      # cfg should have [:jump_groups]
      attr_reader :sub_list
      def initialize(cfg,attr={})
        type?(cfg,Config)
        super(PROJ,cfg)
        @sub_list=@cfg[:sub_list]=Wat::List.new(@cfg)
        @list=List.new(PROJ,@cfg)
        @lastsize=0
        @cobj=Index.new(@cfg)
        @cobj.add_rem.add_hid
        @cobj.rem.add_int
        @cobj.rem.int.add_item('clean','Clean list')
        @cobj.rem.add_ext(Db.new.get(PROJ))
        @parameter=@cobj.rem.int.par
        @list.post_upd_procs << proc{
          @parameter[:list]=@list.keys
        }
        #Set sublist
        @mdb=@cobj.rem.ext.cfg[:dbi]
        @cfg['host']||=@mdb['host']
        @cfg['port']||=(@mdb['port']||5555)
      end

      def ext_shell
        extend(Shell).ext_shell
      end
    end

    class Cl < Exe
      def initialize(cfg,attr={})
        super
        @pre_exe_procs << proc{@list.upd}
        @list.ext_http
        ext_client
      end
    end

    class Sv < Exe
      def initialize(cfg,attr={})
        super
        self['sid']='' # For server response
        @pre_exe_procs << proc{ self['sid']='' }
        @list.ext_sv
        # External Command Group
        @cobj.rem.ext.def_proc{|ent| set(ent);"ACCEPT"}
        # Internal Command Group
        @cfg[:submcr_proc]=proc{|args,pid|
          set(@cobj.set_cmd(args),pid)
        }
        @cobj.rem.int.def_proc{|ent|
          if seq=@list.get(ent.par[0])
            self['sid']=seq.record['id']
            seq.exe(ent.id.split(':'))
            ''
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
      end

      private
      def set(ent,pid='0')
        @list.add(ent,pid)
      end
    end

    module Shell
      include CIAX::Shell
      def ext_shell
        super
        @current=0
        @prompt_proc=proc{
          ("[%d]%s" % [@current,upd_current])
        }
        # Convert as command
        input_conv_num{|i|
          set_current(i) ? nil : ''
        }
        # Convert as parameter
        input_conv_num(@cobj.rem.int.keys){|i|
          set_current(i)
        }
        @cfg[:output]=@list
        @post_exe_procs << proc{@cfg[:output].upd}
        @cobj.loc.add_view
        @records={'0' => @list}
        self
      end

      private
      def set_current(i)
        return false if i > @list.size
        if i==0
          id='0'
        else
          id=@list.keys[i-1]
          @seq=@list.get(id)
          @records[id]||= (Seq === @seq) ? @seq.record : Record.new(id).ext_http
        end
        @parameter[:default]=id
        @cfg[:output]=@records[id]
        @current=i
      end

      def upd_current
        if @current > @list.size or @list.size > @lastsize
          set_current(@lastsize=@list.size)
        end
        if @current > 0
          "(#{@seq['stat']})"+optlist(@seq['option'])
        end
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('cmnlrt')
      begin
        cfg=Config.new
        cfg[:jump_groups]=[]
        Mcr.new(cfg).ext_shell.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
