#!/usr/bin/ruby
require "libdatax"
require "liblocal"

module CIAX
  # This is parent of Layer List, Site List.
  # @cfg should have [:jump_groups]
  # attr should have [:jump_class] (Used in Local::Jump::Group)
  class List < DataH
    attr_reader :cfg,:jumpgrp
    # level can be Layer or Site
    def initialize(cfg,attr={})
      @cfg=cfg.gen(self).update(attr)
      super(m2id(@cfg[:obj].class,-2),@cfg[:data_struct]||{},@cfg[:data_name]||'list')
      $opt||=GetOpts.new
    end

    def ext_shell(jump_class)
      extend(Shell).ext_shell(jump_class)
    end

    module Shell
      def self.extended(obj)
        Msg.type?(obj,List)
      end

      def ext_shell(jump_class)
        @cfg[:jump_class]=type?(jump_class,Module)
        @jumpgrp=Local::Jump::Group.new(@cfg)
        type?(@cfg[:jump_groups],Array)
        @cfg[:jump_groups]+=[@jumpgrp]
        self
      end
    end
  end
end
