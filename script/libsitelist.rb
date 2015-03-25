#!/usr/bin/ruby
require "liblist"
require "libcommand"
require "libsh"

module CIAX
  module Site
    class List < List
      def initialize(level,inter_cfg={},attr={})
        super
        @cfg[:current_site]||=''
        @db=type?(@cfg[:layer_db],CIAX::Db)
        @jumpgrp.update_lists(@db.list)
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

      def set(id,exe)
        type?(exe,Exe)
        return self if @data.key?(id)
        # JumpGroup is set to Domain
        (@cfg[:jump_groups]+[@jumpgrp]).each{|grp|
          exe.cobj.lodom.join_group(grp)
        }
        super
      end

      def list
        @db.list
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
        cfg=Config.new("site_#{site}",@cfg)
        obj=@level.new(site,cfg)
        set(site,obj.ext_shell)
      end
    end
  end
end
