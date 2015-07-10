#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  module Mcr
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_group],[:layer_list]
    class List < CIAX::List
      attr_reader :current
      def initialize(cfg,attr={})
        super
        @cfg[:submcr_proc]=proc{|args,id| add(args,id) }
        @current=''
        verbose("Initialize")
        @mobj=Index.new(@cfg)
        @mobj.add_rem.add_ext(Db.new.get('ciax'))
      end

      def get(sid)
        @mobj.set_cmd unless res=super
        @current=sid
        res
      end

      def add(args,parent='user')
        ent=@mobj.set_cmd(args)
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
      al=Wat::List.new(cfg).cfg[:sub_list] #Take App List
      cfg[:sub_list]=al
      list=List.new(cfg).ext_shell
      begin
        ARGV.each{|cid|
          list.add(cid.split(':'))
        }
        list.shell
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
