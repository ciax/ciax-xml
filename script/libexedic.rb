#!/usr/bin/env ruby
require 'libdic'
require 'libcmdlocal'

module CIAX
  # This is parent of Layer ExeDic, Site ExeDic.
  # Having :dic(Array) key
  # Access :dic with get() directly
  class ExeDic < Varx
    include Dic
    attr_reader :cfg
    # level can be Layer or Site
    def initialize(spcfg, atrb = Hashx.new)
      @cfg = spcfg.gen(self).update(atrb)
      super(m2id(@cfg[:obj].class, -2))
      @opt = @cfg[:opt]
      verbose { 'Initiate ExeDic (option:' + @opt.keys.join + ')' }
      ext_dic(:dic)
    end

    def shell
      ext_shell.shell
    end

    def ext_shell
      smod = context_module('Shell')
      return self if is_a?(smod)
      extend(smod).ext_shell
    end

    # Shell module
    module Shell
      attr_reader :jumpgrp
      def self.extended(obj)
        Msg.type?(obj, ExeDic)
      end

      # atrb should have [:jump_class] (Used in Local::Jump::Group)
      def ext_shell
        verbose { 'Initiate ExeDic Shell' }
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
        get(site) || cfg_err('Mcr ExeDic is empty')
      end
    end
  end
end
