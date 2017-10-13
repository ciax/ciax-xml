#!/usr/bin/ruby
require 'liblist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::List
    def initialize(cfg)
      super
      obj = yield(@cfg)
      loop do
        ns = m2id(obj.class, -2)
        @list.put(ns, obj)
        obj = obj.sub_list || break
      end
    end

    def ext_shell
      extend(CIAX::List::Shell).ext_shell(Jump)
      @cfg[:jump_layer] = @jumpgrp
      @list.keys.each do |id|
        @list.get(id).ext_shell
        @jumpgrp.add_item(id, id.capitalize + ' mode')
      end
      @current = @cfg[:opt].layer || @list.keys.first
      self
    end

    class Jump < LongJump; end
  end
end
