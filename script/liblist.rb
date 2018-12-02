#!/usr/bin/ruby
require 'libvarx'
require 'libcmdlocal'

module CIAX
  # This is parent of Layer List, Site List.
  # Having :list(Array) key
  # Access :list with get() directly
  class List < Varx
    attr_reader :cfg
    # level can be Layer or Site
    def initialize(super_cfg, atrb = Hashx.new)
      @cfg = super_cfg.gen(self).update(atrb)
      super(m2id(@cfg[:obj].class, -2))
      @opt = @cfg[:opt]
      verbose { 'Initiate List (option:' + @opt.keys.join + ')' }
      self[:list] = Hashx.new
    end

    def ext_shell(jump_class)
      extend(Shell).ext_shell(jump_class)
    end

    def get(id)
      _list.get(id)
    end

    def put(id, obj)
      _list.put(id, obj)
      cmt
    end

    def to_a
      _list.keys
    end

    private

    def _list
      self[:list]
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
        switch(@current).shell
      rescue @cfg[:jump_class]
        @current = $ERROR_INFO.to_s
        retry
      rescue InvalidARGS
        @opt.usage('(opt) [id]')
      end

      def switch(site)
        obj = get(site)
        return obj if obj.is_a?(Shell) || obj.is_a?(CIAX::Exe::Shell)
        obj.ext_shell
      end
    end
  end
end
