#!/usr/bin/ruby
require 'libcommand'

module CIAX
  module Local
    include Command
    # Instance var is @loc in Index
    class Domain < GrpAry
      def initialize(cfg,attr={})
        super
        @cfg[:domain_id]='local'
      end

      def add_shell
        add(Shell::Group)
      end

      def add_jump
        (@cfg[:jump_groups]||[]).each{|grp| put(grp)}
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
          level=@cfg[:level]
          @cfg['caption']="Switch #{level.name.capitalize}s"
          @cfg['color']=5
          @cfg['column']=3
          @cfg.proc{|ent|
            raise(level::Jump,ent.id)
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
