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

    def shell
      _ext_local_shell.shell
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

    def _ext_local_shell
      smod = context_module('Shell')
      return self if is_a?(smod)
      extend(smod).ext_local_shell
    end

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
      def ext_local_shell
        verbose { 'Initiate List Shell' }
        @cfg[:jump_class] = context_module('Jump')
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
        get(site)
      end
    end
  end
end
