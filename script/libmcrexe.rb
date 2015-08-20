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
      attr_reader :sub_list,:parameter
      def initialize(cfg,attr={})
        proj=ENV['PROJ']||'ciax'
        type?(cfg,Config)
        super(proj,cfg)
        @sub_list=@cfg[:sub_list]=Wat::List.new(@cfg)
        @cfg[:output]=@list=List.new(proj,@cfg)
        @cobj=Index.new(@cfg)
        @cobj.add_rem.add_hid
        @cobj.rem.add_int
        @cobj.rem.add_ext(Db.new.get(proj))
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
        # External Command Group
        @cobj.rem.ext.def_proc{|ent| set(ent);"ACCEPT"}
        @cobj.get('interrupt').def_proc{|ent|
          @list.interrupt
          'INTERRUPT'
        }
      end

      private
      def set(ent,pid='0')
        @list.add(ent,pid)
      end
    end

    module Shell
      include CIAX::Shell
      attr_reader :parameter

      def ext_shell
        super
        @parameter=@cobj.rem.int.par
        @current=0
        @prompt_proc=proc{
          ("[%d]" % @current)
        }
        @list.post_upd_procs << proc{
          @parameter[:list]=@list.keys
        }
        # Convert as command
        input_conv_num{|i|
          if id=@list.keys[i-1]
            @current=i
            @parameter[:default]=id
            nil
          else
            ''
          end
        }
        # Convert as parameter
        input_conv_num(@cobj.rem.int.keys){|i|
          if id=@list.keys[i-1]
            @current=i
            @parameter[:default]=id
          end
        }
        self
      end

      def set(ent,pid='0')
        seq=super
        @parameter[:default]=seq['id']
        @current+=1
        seq
      end
    end

    if __FILE__ == $0
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
