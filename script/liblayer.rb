#!/usr/bin/ruby
require 'liblist'
require 'libhexexe'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::List
    def initialize(atrb = {})
      atrb[:column] = 3
      super(Config.new, atrb)
      obj = (OPT[:x] ? Hex::List : Wat::List).new(@cfg)
      loop do
        put(m2id(obj.class, -2), obj)
        obj = obj.sub_list || break
      end
    end

    def ext_shell
      extend(Shell).ext_shell
    end

    module Shell
      include CIAX::List::Shell
      class Jump < LongJump; end

      def ext_shell
        super(Jump)
        @cfg[:jump_groups] = [@jumpgrp]
        keys.each do|id|
          get(id).ext_shell
          @jumpgrp.add_item(id, id.capitalize + ' mode')
        end
        @current ||= OPT.layer || keys.first
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('els')
      Layer.new(site: ARGV.shift).ext_shell.shell
    end
  end
end
