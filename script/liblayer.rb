#!/usr/bin/ruby
require "liblist"

module CIAX
  module Layer
    class List < CIAX::List
      def initialize
        super(Config.new)
      end

      # list object can be (Frm,App,Wat,Hex)
      def set(mod)
        obj=mod.new(@cfg)
        begin
          put(m2id(obj.class,-2),obj)
        end while obj=obj.sub_list
        self
      end

      def ext_shell(site=nil)
        extend(Shell).ext_shell(site)
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell(site)
          super(Jump)
          @cfg[:jump_groups]=[@jumpgrp]
          keys.each{|id|
            sl=get(id).set(site).ext_shell
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
      site=ARGV.shift
      ll=List.new
      begin
        ll.set(Wat::List)
        ll.ext_shell(site).shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
