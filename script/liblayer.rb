#!/usr/bin/ruby
require "liblist"

module CIAX
  module Layer
    class List < CIAX::List
      def initialize(cfg,attr={})
        attr[:layer_list]=self
        super
        @current=''
      end

      # list object can be (Frm,App,Wat,Hex)
      def add(layer)
        type?(layer,Module)
        sl=layer.new(@cfg)
        id=@current=m2id(layer,-2)
        put(id,sl)
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

    if __FILE__ == $0
      require "libmcrman"
      GetOpts.new("els")
      site=ARGV.shift
      cfg=Config.new
      cfg[:jump_groups]=[]
      ll=List.new(cfg)
      begin
        ll.add(App::List)
        ll.ext_shell
        ll.shell(site)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
