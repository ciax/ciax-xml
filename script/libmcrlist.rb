#!/usr/bin/ruby
require "libmcrexe"
module CIAX
  module Mcr
    # Sequencer Layer List
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_group],[:layer_list]
    class List < CIAX::List
      def initialize(cfg,attr={})
        super
        @current=''
        verbose("Initialize")
      end

      def get(sid)
        @current=sid
        super
      end

      def add(ent,parent='user')
        seq=Seq.new(ent.cfg,{'parent' => parent})
        @current=seq.id
        @jumpgrp.add_item(@current,seq['cid'])
        put(@current,seq)
        seq
      end

      def ext_shell
        super(Jump)
        @cfg[:sub_list].ext_shell if @cfg.key?(:sub_list) # Limit self level
        @shlist={}
        self
      end

      def shell
        sid=@current
        begin
          (@shlist[sid]||=Exe.new(get(sid)).ext_shell).shell
        rescue Jump
          sid=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [site]')
        end
      end

      class Jump < LongJump; end
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
