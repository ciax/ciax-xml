#!/usr/bin/ruby
require 'libcommand'

module CIAX
  module Cmd
    # Local Commands
    module Local
      # Top level
      class Index < GrpAry
        # cfg should have [:jump_class]
        attr_reader :loc
        def initialize(cfg, atrb = {})
          super
          @loc = add(Domain)
        end
      end

      # Local Domain
      class Domain < GrpAry
        def add_shell
          add(Sh::Group)
        end

        def add_jump
          @cfg[:jump_groups].each { |grp| append(grp) }
          [:jump_site, :jump_layer].each do |jk|
            append(@cfg[jk]) if @cfg[jk]
          end
        end

        def add_view(atrb = {})
          add(View::Group, atrb)
        end
      end

      module Sh
        # Shell Group
        class Group < Dummy
          def initialize(cfg, atrb = {})
            atrb[:caption] = 'Shell Command'
            atrb[:color] = 1
            super
            add_dummy('q', 'Quit')
            add_dummy('^D,^C', 'Interrupt')
          end
        end
      end

      module Jump
        # Jump Group
        class Group < Group
          def initialize(cfg, atrb = {})
            name = m2id(cfg[:jump_class], 1).capitalize
            atrb[:caption] = "Switch #{name}s"
            atrb[:color] = 5
            super
            def_proc do|ent|
              # Use shell() of top level class
              #  (ie. List.new.get(id).shell -> List.new.shell(id) )
              fail(ent[:jump_class], ent.id)
            end
          end

          def number_item(ary)
            clear
            i = 0
            type?(ary, Array).each do|str|
              add_item((i += 1).to_s, str)
            end
            self
          end

          def ext_grp
            @displist = @displist.ext_grp
            self
          end
        end
      end

      module View
        # Switch View Group
        # cfg should have [:output]
        class Group < Group
          def initialize(cfg, atrb = {})
            atrb.update(caption: 'Change View Mode', column: 2, color: 9)
            super
            add_item('vis', 'Visual mode').def_proc do
              @cfg[:output].vmode(:v)
            end
            add_item('raw', 'Raw Print mode').def_proc do
              @cfg[:output].vmode(:r)
            end
          end
        end
      end

      if __FILE__ == $PROGRAM_NAME
        cfg = Config.new(jump_class: Local::Jump)
        jg = Jump::Group.new(cfg)
        jg.add_item('site', 'Jump to site')
        cfg[:jump_groups] = [jg]
        loc = Index.new(cfg).loc
        loc.add_view
        loc.add_shell
        puts loc.view_list
      end
    end
  end
end
