#!/usr/bin/ruby
require 'libcommand'

module CIAX
  # Command Structure
  module CmdTree
    include CmdBase
    # Command Index
    class Index < Index
      # cfg should have [:jump_class]
      attr_reader :loc
      def initialize(cfg, atrb = Hashx.new)
        super
        @loc = add_dom('Local')
      end
    end

    # Local Commands
    module Local
      include CmdBase
      # Local Domain
      class Domain < Domain
        def add_shell # returns Group
          add_grp('Sh')
        end

        def add_jump # returns Array(Symbols)
          @cfg[:jump_groups].each { |grp| append(grp) }
          %i(jump_site jump_layer).each do |jk|
            append(@cfg[jk]) if @cfg[jk]
          end
        end

        def add_view(atrb = Hashx.new) # retuns Group
          add_grp('View', atrb)
        end

        def add_page(atrb = Hashx.new)
          add_grp('Page', atrb)
        end
      end

      # Shell Commands
      module Sh
        include CmdBase
        # Shell Group
        class Group < Group
          def initialize(cfg, atrb = Hashx.new)
            atrb[:caption] = 'Shell Command'
            atrb[:color] = 1
            super
            add_dummy('q', 'Quit')
            add_dummy('^D,^C', 'Interrupt')
          end
        end
      end

      # Jump Commands
      module Jump
        deep_include CmdBase
        # Jump Group
        class Group < CmdBase::Group
          def initialize(cfg, atrb = Hashx.new)
            name = m2id(cfg[:jump_class], 1).capitalize
            atrb[:caption] = "Switch #{name}s"
            atrb[:color] = 5
            super
            def_proc do |ent|
              # Use shell() of top level class
              #  (ie. List.new.get(id).shell -> List.new.shell(id) )
              raise(ent[:jump_class], ent.id)
            end
          end

          def number_item(ary)
            clear
            i = 0
            type?(ary, Array).each do |str|
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

      # Switch View Group
      module View
        deep_include CmdBase
        # cfg should have [:output]
        class Group < CmdBase::Group
          def initialize(cfg, atrb = Hashx.new)
            atrb.update(caption: 'Change View Mode', column: 2, color: 9)
            super
            add_item('vis', 'Visual mode').def_proc do
              @cfg[:output].vmode('v')
            end
            add_item('raw', 'Raw Print mode').def_proc do
              @cfg[:output].vmode('o')
            end
          end
        end
      end

      # Switch Page Group
      module Page
        deep_include CmdBase
        # Page Group
        class Group < CmdBase::Group
          def initialize(cfg, atrb = Hashx.new)
            atrb.update(caption: 'Switch Pages', color: 5)
            super
            add_dummy('0', 'List page')
            add_dummy('[1-n]', 'Switch Pages')
            add_item('last', 'Get last item [n]', def_msg: 'UPDATE').add_par(type: 'reg', list: ['^[0-9]+$'])
            add_item('cl', 'Clean list', def_msg: 'CLEAN')
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
