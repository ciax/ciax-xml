#!/usr/bin/env ruby
require 'libexedic'

module CIAX
  # element object can be (Frm,App,Wat,Hex)
  class Layer < CIAX::ExeDic
    def initialize(top_cfg)
      super(top_cfg)
      obj = yield(@cfg)
      # Initialize all sub layers
      loop do
        ns = m2id(obj.class, -2)
        put(ns, obj)
        obj = obj.sub_dic || break
      end
    end

    # Shell module which is Layer specific
    module Shell
      include CIAX::ExeDic::Shell
      def ext_shell
        super
        @cfg[:jump_layer] = @jumpgrp
        _dic.each do |id, _obj|
          @jumpgrp.add_form(id, id.capitalize + ' mode')
        end
        @current = @cfg[:opt].init_layer || _dic.keys.first
        self
      end
    end

    class Jump < LongJump; end
  end
end
