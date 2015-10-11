#!/usr/bin/ruby
require 'liblist'

module CIAX
  module Site
    # list object can be (Frm,App,Wat,Hex)
    # attr can have [:top_layer]
    class Layer < CIAX::List
      def initialize(attr = {})
        super(Config.new, attr)
        obj = (OPT['x'] ? Hex::List : Wat::List).new(@cfg)
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
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libhexexe'
      OPT.parse('els')
      begin
        Layer.new(site: ARGV.shift).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
