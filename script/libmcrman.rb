#!/usr/bin/ruby
require "libsh"
require "libmcrlist"

module CIAX
  module Mcr
    module Man
      def self.new(cfg=Config.new('mcr'))
        if $opt['l']
          $opt.delete('l')
          cfg['host']='localhost'
          Sv.new(cfg)
          Cl.new(cfg)
        elsif $opt['c'] || $opt['h']
          Cl.new(cfg)
        elsif $opt['t']
          Exe.new(cfg)
        else
          Sv.new(cfg)
        end
      end

      class Exe < CIAX::Exe
        # cfg should have [:jump_groups]
        attr_reader :sub_list,:parameter
        def initialize(cfg,attr={})
          proj=ENV['PROJ']||'ciax'
          type?(cfg,Config)
          super(proj,cfg)
          @cfg[:output]=@list=List.new(proj,@cfg)
          @cobj=Index.new(@cfg)
          @cobj.add_rem.add_hid
          @cobj.rem.add_ext(Db.new.get(proj))
          @cobj.rem.add_int
          @cfg[:submcr_proc]=proc{|args,id|
            @list.add(@cobj.set_cmd(args),id).start(true)
          }
          #Set sublist
          @sub_list=@cfg[:sub_list]=Wat::List.new(@cfg)
          @mdb=@cobj.rem.ext.cfg[:dbi]
          @cfg['host']||=@mdb['host']
          @cfg['port']||=(@mdb['port']||5555)
        end

        def ext_shell
          extend(Shell).ext_shell
        end
      end

      module Shell
        include CIAX::Shell
        attr_reader :parameter

        def ext_shell
          super
          @index=0
          @parameter=@cobj.rem.int.par
          @prompt_proc=proc{
            ("[%d]" % @index)
          }
          @list.post_upd_procs << proc{
            list=@parameter[:list]=@list.keys
            i=0
            list.size.times{ list << (i+=1).to_s }
          }
          input_conv_num{|i|
            if i == 0 || id=@list.keys[i-1]
              @index=i
              @parameter[:default]=id
              nil
            else
              ''
            end
          }
          input_conv_num(@cobj.rem.int.keys){|i|
            id=@list.include?(i.to_s) ? i.to_s : @list.keys[i-1]
            if id
              @index=i
              @parameter[:default]=id
            end
          }
          @cobj.loc.add_view
          self
        end
      end

      class Cl < Exe
        def initialize(cfg)
          super
          @pre_exe_procs << proc{@list.upd}
          @list.ext_http(@cfg['host'])
          ext_client
        end
      end

      class Sv < Exe
        def initialize(cfg)
          cfg[:submcr_proc]=proc{|args,src| exe(args,src)}
          super
          self['sid']='' # For server response
          @pre_exe_procs << proc{ self['sid']='' }
          @list.ext_save
          # Internal Command Group
          @cobj.rem.int.def_proc{|ent|
            id=ent.par[0]
            if seq=@list.get(id)
              self['sid']=seq['id']
              seq.reply(ent.id)
            else
              "NOSID"
            end
          }
          # External Command Group
          @cobj.rem.ext.def_proc{|ent|
            @list.add(ent).start(true)
            "ACCEPT"
          }
          @cobj.get('interrupt').def_proc{|ent|
            @list.interrupt
            'INTERRUPT'
          }
          ext_server
        end
      end

      if __FILE__ == $0
        GetOpts.new('mnlrt')
        begin
          cfg=Config.new
          cfg[:jump_groups]=[]
          Man.new(cfg).ext_shell.shell
        rescue InvalidCMD
          $opt.usage("[mcr] [cmd] (par)")
        end
      end
    end
  end
end
