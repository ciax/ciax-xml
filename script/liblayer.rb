#!/usr/bin/ruby
require "liblist"

module CIAX
  module Layer
    class List < CIAX::List
      def initialize(cfg,attr={})
        super
      end

      # list object can be (Frm,App,Wat,Hex)
      def set(obj)
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
          @cfg[:jump_groups] << @jumpgrp
          keys.each{|id|
            sl=get(id).ext_shell
            @jumpgrp.add_item(id,id.capitalize+" mode",{:parameters => [sl.parameter]})
          }
          @current=keys.first
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
      require "libhexexe"
      GetOpts.new("els")
      site=ARGV.shift
      cfg=Config.new
      cfg[:jump_groups]=[]
      ll=List.new(cfg)
      begin
        ll.set(Wat::List.new(cfg))
        ll.ext_shell
        ll.shell(site)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
