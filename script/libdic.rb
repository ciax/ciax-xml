#!/usr/bin/env ruby
require 'libvarx'
require 'libcmdlocal'

module CIAX
  # This is parent of Layer Dic, Site Dic.
  # Having :dic(Array) key
  # Access :dic with get() directly
  class Dic < Varx
    attr_reader :cfg
    # level can be Layer or Site
    def initialize(spcfg, atrb = Hashx.new)
      @cfg = spcfg.gen(self).update(atrb)
      super(m2id(@cfg[:obj].class, -2))
      _attr_set
      @opt = @cfg[:opt]
      verbose { 'Initiate Dic (option:' + @opt.keys.join + ')' }
      self[:dic] = Hashx.new
    end

    def get(id)
      _dic.get(id)
    end

    def put(id, obj)
      _dic.put(id, obj)
      cmt
    end

    def to_a
      _dic.keys
    end

    def each
      _dic.each { |e| yield e }
    end

    def shell
      ext_local_shell.shell
    end

    def ext_local_shell
      smod = context_module('Shell')
      return self if is_a?(smod)
      extend(smod).ext_local_shell
    end

    private

    def _dic
      self[:dic]
    end

    # Shell module
    module Shell
      attr_reader :jumpgrp
      def self.extended(obj)
        Msg.type?(obj, Dic)
      end

      # atrb should have [:jump_class] (Used in Local::Jump::Group)
      def ext_local_shell
        verbose { 'Initiate Dic Shell' }
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
        get(site) || cfg_err('Mcr Dic is empty')
      end
    end
  end
end
