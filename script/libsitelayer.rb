#!/usr/bin/ruby
require 'libhexlist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  module Site
    class Layer < CIAX::List
      def initialize(atrb = {})
        atrb[:column] = 4
        atrb[:db] = Ins::Db.new
        super(Config.new, atrb)
        obj = (OPT[:x] ? Hex::List : Wat::List).new(@cfg)
        loop do
          @list.put(m2id(obj.class, -2), obj)
          obj = obj.sub_list || break
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
          @cfg[:jump_groups] = [@jumpgrp]
          @list.keys.each do|id|
            @list.get(id).ext_shell
            @jumpgrp.add_item(id, id.capitalize + ' mode')
          end
          @current ||= OPT.layer || @list.keys.first
          self
        end
      end

      if __FILE__ == $PROGRAM_NAME
        OPT.parse('els')
        Layer.new(site: ARGV.shift).ext_shell.shell
      end
    end
  end
end
