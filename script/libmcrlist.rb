#!/usr/bin/ruby
require "libmcrexe"
module CIAX
  module Mcr
    # Sequencer Layer List
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_group],[:layer_list]
    class List < CIAX::List
      def initialize(cfg,attr={})
        attr[:data_struct]=[]
        super
        verbose("Initialize")
      end

      def get(id)
        super(id.to_i-1)
      end

      def add(ent,parent='user')
        seq=Seq.new(ent.cfg,{'parent' => parent})
        @data.push seq
        seq
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          @cfg[:sub_list].ext_shell if @cfg.key?(:sub_list) # Limit self level
          @exelist={}
          self
        end

        def get(id)
          @exelist[id]||=Exe.new(super).ext_shell
        end

        def add(ent,parent='user')
          seq=super
          id=@data.size.to_s
          @jumpgrp.add_item(id,seq['cid'])
          seq
        end

        def shell
          id=@data.size.to_s
          begin
            get(id).shell
          rescue Jump
            id=$!.to_s
            retry
          rescue InvalidID
            $opt.usage('(opt) [site]')
          end
        end
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('tenr')
      proj=ENV['PROJ']||'ciax'
      cfg=Config.new
      cfg[:jump_groups]=[]
      cfg[:sub_list]=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      list=List.new(cfg).ext_shell
      mobj=Index.new(list.cfg)
      mobj.add_rem.add_ext(Db.new.get(proj))
      cfg[:submcr_proc]=proc{|args,id|
        ent=mobj.set_cmd(args)
        list.add(ent,id)
      }
      begin
        mobj.set_cmd if ARGV.empty?
        ARGV.each{|cid|
          ent=mobj.set_cmd(cid.split(':'))
          list.add(ent)
        }
        list.shell
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
