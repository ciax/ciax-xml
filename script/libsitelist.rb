#!/usr/bin/ruby
require "liblist"
require "libcommand"
require "libsitedb"
require "libsh"

module CIAX
  module Site
    class Layer < List
      def initialize(attr={},upper={})
        super(Site,attr,upper)
        @cfg[:site_stat]=Prompt.new
        @cfg[:current_site]||=''
        @pars={:parameters => [{:default => @cfg[:current_site]}]}
        @cfg[:jump_groups] << @jumpgrp
      end

      def add_layer(layer)
        type?(layer,Module)
        str=layer.to_s.split(':').last
        layer::List.new(@cfg)
        @layer=str.downcase
        @cfg.layers.each{|k,v|
          id=k.to_s
          @jumpgrp.add_item(id,str+" mode",@pars)
          set(id,v)
        }
      end

      def shell(id)
        layer=@layer
        begin
          dst=get(layer)
          if dst.list.key?(id)
            last=dst
          else
            dst=last
          end
          dst.shell(id)
        rescue Site::Jump
          layer,id=$!.to_s.split(':')
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end
    end

    # Site List
    class List < List
      def initialize(level,list_cfg={},upper={})
        super
        @cfg[:current_site]||=''
        @db=@cfg[:layer_db]
        @jumpgrp.update_items(@db.list)
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
        cfg['id']=site
        obj=@level.new(cfg)
        set(site,obj.ext_shell)
      end
    end

    class Jump < LongJump; end
  end
end
