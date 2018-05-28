#!/usr/bin/ruby
require 'libvarx'
require 'libcmdlocal'

module CIAX
  # This is parent of Layer List, Site List.
  class List < Varx
    attr_reader :cfg
    # level can be Layer or Site
    def initialize(cfg, atrb = Hashx.new)
      @cfg = cfg.gen(self).update(atrb)
      @cfg[:jump_groups] ||= []
      super(m2id(@cfg[:obj].class, -2))
      verbose { 'Initiate List (option:' + @cfg[:opt].keys.join + ')' }
      self[:list] = Hashx.new
    end

    def ext_shell(jump_class)
      extend(Shell).ext_shell(jump_class)
    end

    private

    def _list
      self[:list]
    end

    def _switch(id)
      _list.get(id)
    end

    # Shell module
    module Shell
      require 'libsh'
      attr_reader :jumpgrp
      def self.extended(obj)
        Msg.type?(obj, List)
      end

      # atrb should have [:jump_class] (Used in Local::Jump::Group)
      def ext_shell(jump_class)
        verbose { 'Initiate List Shell' }
        @cfg[:jump_class] = type?(jump_class, Module) # Use for libcmdlocal
        @jumpgrp = CmdTree::Local::Jump::Group.new(@cfg)
        self
      end

      def shell
        _switch(@current).shell
      rescue @cfg[:jump_class]
        @current = $ERROR_INFO.to_s
        retry
      rescue InvalidARGS
        @cfg[:opt].usage('(opt) [id]')
      end

      private

      def _switch(site)
        obj = super(site)
        return obj if obj.is_a?(Shell) || obj.is_a?(CIAX::Exe::Shell)
        obj.ext_shell
      end
    end
  end
end
