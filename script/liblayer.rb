#!/usr/bin/ruby
require "liblist"

module CIAX
  module Layer
    class List < CIAX::List
      def initialize(attr={})
        super(Config.new,attr)
      end

      # list object can be (Frm,App,Wat,Hex)
      def set(mod)
        obj=mod.new(@cfg)
        begin
          put(m2id(obj.class,-2),obj)
        end while obj=obj.sub_list
        self
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          @cfg[:jump_groups]=[@jumpgrp]
          keys.each{|id|
            sl=get(id).ext_shell
            @jumpgrp.add_item(id,id.capitalize+" mode")
          }
          @current=keys.first
          self
        end
      end
    end

    if __FILE__ == $0
      require "libhexexe"
      GetOpts.new("els")
      ll=List.new(:site => ARGV.shift)
      begin
        ll.set(Wat::List)
        ll.ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
