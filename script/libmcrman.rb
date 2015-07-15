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
        # cfg should have [:jump_groups],[:sub_list](App::List)
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
          @index=0
          ext_shell
        end

        private
        def ext_shell
          super
          @prompt_proc=proc{
            ("[%d]" % @index)
          }
          @list.post_upd_procs << proc{
            @cobj.rem.int.par[:list]=@list.keys
          }
          conv_num{|i|
            if id=@list.keys[i-1]
              @index=i
              set_crnt(id)
              nil
            else
              i
            end
          }
          vg=@cobj.loc.add_view
          vg.add_item('lst',"List mode").def_proc{@cfg[:output]=@list;''}
          vg.add_item('seq',"Sequencer mode").def_proc{@cfg[:output]=@list.get(@crnt);''}
          self
        end

        def set_crnt(id)
          @crnt=@cobj.rem.int.par[:default]=id
        end
      end

      class Cl < Exe
        def initialize(cfg)
          super
          host=cfg['host']||@cobj.cfg[:dbi]['host']||'localhost'
          port=cfg['port']||@cobj.cfg[:dbi]['port']||55555
          @pre_exe_procs << proc{@list.upd}
          ext_client(host,port)
        end
      end

      class Sv < Exe
        def initialize(cfg)
          cfg[:submcr_proc]=proc{|args,src| exe(args,src)}
          super
          port=cfg['port']||@cobj.rem.ext.cfg[:dbi]['port']||55555
          self['sid']='' # For server response
          @pre_exe_procs << proc{ self['sid']='' }
          @list.ext_save
          # Internal Command Group
          @cobj.rem.int.def_proc{|ent|
            id=ent.par[0]
            if seq=@list.get(id)
              set_crnt(id)
              self['sid']=seq['id']
              seq.reply(ent.id)
            else
              "NOSID"
            end
          }
          # External Command Group
          @cobj.rem.ext.def_proc{|ent|
            seq=@list.add(ent).start(true)
            @index=@list.size
            set_crnt(seq['id'])
            "ACCEPT"
          }
          @cobj.get('interrupt').def_proc{|ent|
            @list.interrupt
            'INTERRUPT'
          }
          ext_server(port)
        end
      end

      if __FILE__ == $0
        GetOpts.new('mnlrt')
        begin
          cfg=Config.new
          cfg[:jump_groups]=[]
          wl=Wat::List.new(cfg)
          cfg[:sub_list]=wl.cfg[:sub_list] #Take App List
          Man.new(cfg).shell
        rescue InvalidCMD
          $opt.usage("[mcr] [cmd] (par)")
        end
      end
    end
  end
end
