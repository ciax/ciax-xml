#!/usr/bin/ruby
require "liblist"
require "libcommand"
require "libsitedb"

module CIAX
  module Site
    class Layer < List
      def initialize(upper=nil)
        super(Site,upper)
        @cfg[:site]||=''
        @cfg[:ldb]||=Site::Db.new
        @pars={:parameters => [{:default => @cfg[:site]}]}
        @cfg[:jump_groups] << @jumpgrp
      end

      def add_layer(layer)
        type?(layer,Module)
        str=layer.to_s.split(':')[1]
        id=str.downcase.to_sym
        layer::List.new(@cfg)
        @cfg.layers.each{|k,v|
          id=k.to_s
          @jumpgrp.add_item(id,str+" mode",@pars)
          set(id,v)
        }
      end
    end

    # Site List
    class List < List
      # shdom: Domain for Shared Command Groups
      def initialize(level,upper=nil)
        super(level,upper)
        @cfg[:site]||=''
        @cfg[:ldb]||=Db.new
        @jumpgrp.update_items(@cfg[:ldb].list)
        verbose("List","Initialize")
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args,'local')
      end

      def get(site)
        add(site) unless @data.key?(site)
        @cfg[:site].replace(site)
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

      def server(ary)
        ary.each{|i|
          sleep 0.3
          get(i)
        }.empty? && get(nil)
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end
    end

    class Jump < LongJump; end
  end
end
