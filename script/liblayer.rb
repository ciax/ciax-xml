#!/usr/bin/ruby
require 'libdic'

module CIAX
  # element object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::Dic
    def initialize(top_cfg)
      super(top_cfg)
      obj = yield(@cfg, top_cfg[:opt].init_layer_mod)
      # Initialize all sub layers
      loop do
        ns = m2id(obj.class, -2)
        _dic.put(ns, obj)
        obj = obj.sub_dic || break
      end
    end

    def ext_local_shell
      super
      @cfg[:jump_layer] = @jumpgrp
      _dic.each do |id, _obj|
        @jumpgrp.add_item(id, id.capitalize + ' mode')
      end
      @current = @cfg[:opt].init_layer || _dic.keys.first
      self
    end

    class Jump < LongJump; end
  end
end
