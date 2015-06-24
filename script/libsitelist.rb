#!/usr/bin/ruby
require "liblist"
require "libsh"

module CIAX
  module Site
    class List < List
      def initialize(level,cfg,attr={})
        super
        @cfg[:current_site]||=''
        @db=type?(@cfg[:layer_db],CIAX::Db)
        @jumpgrp.merge_items(@db.displist)
        verbose("List","Initialize")
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args,'local')
      end

      def get(site)
        unless @data.key?(site)
          add(site)
        end
        @cfg[:current_site].replace(site)
        super
      end

      def put(id,exe)
        type?(exe,Exe)
        return self if @data.key?(id)
        # JumpGroup is set to Domain
        (@cfg[:jump_groups]+[@jumpgrp]).each{|grp|
          exe.cobj.loc.put(grp)
        }
        super
      end

      def shell(id)
        begin
          get(id).shell
        rescue @level::Jump
          id=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end

      def server(ary)
        ary.each{|i|
          sleep 0.3
          get(i)
        }.empty? && get(nil)
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end

      private
      def add(site)
        cfg=@cfg.gen("site_#{site}")
        obj=@level.new(site,cfg)
        put(site,obj.ext_shell)
      end
    end
  end
end
