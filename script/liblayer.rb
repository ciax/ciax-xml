#!/usr/bin/ruby
require 'liblist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::List
    def initialize(cfg)
      super(cfg)
      obj = yield(@cfg).run
      # Initialize all sub layers
      loop do
        ns = m2id(obj.class, -2)
        _list.put(ns, obj)
        obj = obj.sub_list || break
      end
    end

    def ext_shell
      extend(CIAX::List::Shell).ext_shell(Jump)
      @cfg[:jump_layer] = @jumpgrp
      _list.each do |id, obj|
        obj.ext_shell
        @jumpgrp.add_item(id, id.capitalize + ' mode')
      end
      @current = @cfg[:opt].init_layer || _list.keys.first
      self
    end

    class Jump < LongJump; end
  end
end
