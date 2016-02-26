#!/usr/bin/ruby
require 'liblist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::List
    def initialize(usagestr, optstr)
      GetOpts.new(usagestr, optstr) do |opt|
        cfg = Config.new(column: 4, option: opt)
        super(cfg)
        obj = yield(opt).new(@cfg)
        loop do
          ns = m2id(obj.class, -2)
          @list.put(ns, obj)
          obj = obj.sub_list || break
        end
      end
    end

    def ext_shell
      extend(Shell).ext_shell
    end

    # Shell Extension
    module Shell
      include CIAX::List::Shell
      class Jump < LongJump; end

      def ext_shell
        super(Jump)
        @cfg[:jump_layer] = @jumpgrp
        @list.keys.each do|id|
          @list.get(id).ext_shell
          @jumpgrp.add_item(id, id.capitalize + ' mode')
        end
        @current ||= @list.keys.first
        self
      end
    end
  end
end
