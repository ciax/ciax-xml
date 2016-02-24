#!/usr/bin/ruby
require 'libvarx'
require 'libcmdlocal'

module CIAX
  # This is parent of Layer List, Site List.
  class List < Varx
    attr_reader :cfg
    # level can be Layer or Site
    def initialize(cfg, atrb = {})
      @cfg = cfg.gen(self).update(atrb)
      @cfg[:jump_groups] ||= []
      super(m2id(@cfg[:obj].class, -2))
      @cls_color = 6
      @list = self[:list] = Hashx.new
    end

    def ext_shell(jump_class)
      extend(Shell).ext_shell(jump_class)
    end

    private

    def switch(id)
      @list.get(id)
    end

    # Shell module
    module Shell
      attr_reader :jumpgrp
      def self.extended(obj)
        Msg.type?(obj, List)
      end

      # atrb should have [:jump_class] (Used in Local::Jump::Group)
      def ext_shell(jump_class)
        @cfg[:jump_class] = type?(jump_class, Module) # Use for libcmdlocal
        @jumpgrp = Cmd::Local::Jump::Group.new(@cfg)
        self
      end

      def shell
        switch(@current).shell
      rescue @cfg[:jump_class]
        @current = $ERROR_INFO.to_s
        retry
      rescue InvalidID
        @cfg[:option].usage('(opt) [id]')
      end
    end
  end
end
