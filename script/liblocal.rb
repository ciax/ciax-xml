#!/usr/bin/ruby
require 'libcommand'

module CIAX
  module Local
    class Index < GrpAry
      # cfg should have [:jump_class]
      attr_reader :loc
      def initialize(cfg,attr={})
        super
        @loc=add(Domain)
      end
    end

    class Domain < GrpAry
      def add_shell
        add(Sh::Group)
      end

      def add_jump
        (@cfg[:jump_groups]||[]).each{|grp| append(grp)}
        append(@cfg[:jump_site]) if @cfg[:jump_site]
      end

      def add_view(attr={})
        add(View::Group,attr)
      end
    end

    module Sh
      class Group < Group
        def initialize(cfg,attr={})
          super
          @cfg['caption']="Shell Command"
          @cfg['color']=1
          add_dummy('q',"Quit")
          add_dummy('^D,^C',"Interrupt")
        end
      end
    end

    module Jump
      class Group < Group
        def initialize(cfg,attr={})
          super
          name=m2id(@cfg[:jump_class],1).capitalize
          @cfg['caption']="Switch #{name}s"
          @cfg['color']=5
          @cfg['column']=3
          def_proc{|ent|
            # Use shell() of top level class (ie. List.new.get(id).shell -> List.new.shell(id) )
            raise(ent[:jump_class],ent.id)
          }
        end

        def number_item(ary)
          clear
          i=0
          type?(ary,Array).each{|str|
            add_item((i+=1).to_s,str)
          }
          self
        end
      end
    end

    module View
      # cfg should have [:output]
      class Group < Group
        def initialize(cfg,attr={})
          super
          @cfg['caption']="Change View Mode"
          @cfg['color']=9
          add_item('vis',"Visual mode").def_proc{@cfg[:output].vmode='v';''}
          add_item('raw',"Raw Print mode").def_proc{@cfg[:output].vmode='r';''}
        end
      end
    end
  end
end
