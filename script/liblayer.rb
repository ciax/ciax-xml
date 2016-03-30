#!/usr/bin/ruby
require 'liblist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::List
    NS_COLOR=4
    def initialize(usagestr, optstr)
      ConfOpts.new(usagestr, optstr) do |cfg, args, opt|
        super(cfg)
        obj = yield(@cfg, args, opt)
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
        @current = @cfg[:option].layer || @list.keys.first
        self
      end
    end
  end
end
