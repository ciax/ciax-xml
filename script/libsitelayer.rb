#!/usr/bin/ruby
require "liblist"

module CIAX
  module Site
    # list object can be (Frm,App,Wat,Hex)
    # attr can have [:top_layer]
    class Layer < CIAX::List
      def initialize(attr={})
        super(Config.new,attr)
        mod=@cfg[:top_layer]||=$opt.layer_list
        obj=mod.new(@cfg)
        begin
          put(m2id(obj.class,-2),obj)
        end while obj=obj.sub_list
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
          @current||=keys.first
          self
        end
      end
    end

    if __FILE__ == $0
      require "libhexexe"
      GetOpts.new("els")
      begin
        Layer.new(:site => ARGV.shift).ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
