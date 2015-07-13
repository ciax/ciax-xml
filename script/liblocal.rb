#!/usr/bin/ruby
require 'libcommand'

module CIAX
  module Local
    include Command
    class Index < GrpAry
      # cfg should have [:jump_groups],[:jump_class]
      attr_reader :loc
      def initialize(cfg,attr={})
        super
        @loc=add(Domain)
      end
    end

    class Domain < GrpAry
      def add_shell
        add(Shell::Group)
      end

      def add_jump
        (@cfg[:jump_groups]||[]).each{|grp| add(grp)}
      end

      def add_view
        add(View::Group)
      end
    end

    module Shell
      include Command
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
      include Command
      class Group < Group
        def initialize(cfg,attr={})
          super
          name=m2id(@cfg[:jump_class],1).capitalize
          @cfg['caption']="Switch #{name}s"
          @cfg['color']=5
          @cfg['column']=3
          def_proc{|ent|
            # Use shell() of top level class (ie. List.new.get(id).shell -> List.new.shell(id) )
            raise(ent.cfg[:jump_class],ent.id)
          }
        end
      end
    end

    module View
      include Command
      class Group < Group
        def initialize(cfg,attr={})
          super
          @cfg['caption']="Change View Mode"
          @cfg['color']=9
          add_item('vis',"Visual mode")
          add_item('raw',"Raw Print mode")
        end
      end
    end
  end
end
