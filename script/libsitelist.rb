#!/usr/bin/ruby
require "liblist"
require "libsh"

module CIAX
  module Site
    # Db should be set to @cfg at List level
    # Dbi will made and set to @cfg at Exe level

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

      def put(site,exe)
        type?(exe,Exe)
        return self if @data.key?(site)
        # JumpGroup is set to Domain
        (@cfg[:jump_groups]+[@jumpgrp]).each{|grp|
          exe.cobj.loc.put(grp)
        }
        super
      end

      def shell(site)
        begin
          get(site).shell
        rescue @level::Jump
          site=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [site]')
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
