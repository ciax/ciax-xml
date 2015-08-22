#!/usr/bin/ruby
require "libdatax"
require "liblocal"

module CIAX
  # This is parent of Layer List, Site List.
  class List < DataH
    attr_reader :cfg
    # level can be Layer or Site
    def initialize(cfg,attr={})
      @cfg=cfg.gen(self).update(attr)
      super(m2id(@cfg[:obj].class,-2),{},'list')
      $opt||=GetOpts.new
    end

    def ext_shell(jump_class)
      extend(Shell).ext_shell(jump_class)
    end

    module Shell
      attr_reader :jumpgrp
      def self.extended(obj)
        Msg.type?(obj,List)
      end

      # attr should have [:jump_class] (Used in Local::Jump::Group)
      # @cfg should have [:jump_groups]
      def ext_shell(jump_class)
        @cfg[:jump_class]=type?(jump_class,Module) # Use for liblocal
        @jumpgrp=Local::Jump::Group.new(@cfg)
        self
      end

      def shell
        begin
          get(@current).shell
        rescue @cfg[:jump_class]
          @current=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end
    end
  end
end
