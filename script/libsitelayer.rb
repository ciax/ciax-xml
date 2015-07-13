#!/usr/bin/ruby
require "liblist"

module CIAX
  module Site
    class Layer < CIAX::List
      def initialize(cfg,attr={})
        attr[:layer_list]=self
        super
        @current=''
      end

      # list object can be (Frm,App,Wat,Hex)
      def add(layer)
        type?(layer,Module)
        sl=layer::List.new(@cfg)
        put(@current=m2id(layer),sl)
        sl
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          keys.each{|id|
            sl=get(id).ext_shell
            @jumpgrp.add_item(id,id.capitalize+" mode",{:parameters => [sl.parameter]})
          }
          self
        end

        def shell(site)
          layer=@current
          begin
            get(layer).shell(site)
          rescue Jump
            layer,site=$!.to_s.split(':')
            retry
          rescue InvalidID
            $opt.usage('(opt) [id]')
          end
        end
      end
    end
  end

  if __FILE__ == $0
    require "libhexexe"
    GetOpts.new("els")
    site=ARGV.shift
    cfg=Config.new
    cfg[:jump_groups]=[]
    sl=Site::Layer.new(cfg).ext_shell
    begin
      sl.add(Frm)
      sl.shell(site)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
