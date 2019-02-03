#!/usr/bin/env ruby
require 'libcommand'

module CIAX
  # Command Structure
  module CmdTree
    include CmdBase
    # Command Index
    class Index < Index
      # cfg should have [:jump_class]
      attr_reader :loc
      def initialize(spcfg, atrb = Hashx.new)
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
          %i(jump_mcr jump_site jump_layer).each do |jk|
            append(@cfg[jk]) if @cfg[jk]
          end
        end

        def add_view(atrb = Hashx.new) # retuns Group
          add_grp('View', atrb)
        end
      end

      # Shell Commands
      module Sh
        include CmdBase
        # Shell Group
        class Group < Group
          def initialize(spcfg, atrb = Hashx.new)
            atrb[:caption] = 'Shell Command'
            atrb[:color] = 1
            super
            add_dummy('q,^\\', 'Quit')
            add_dummy('^D,^C', 'Interrupt')
          end
        end
      end

      # Jump Commands
      module Jump
        deep_include CmdBase
        # Jump Group
        class Group < CmdBase::Group
          def initialize(spcfg, atrb = Hashx.new)
            name = m2id(spcfg[:jump_class], 1).capitalize
            atrb[:caption] = "Switch #{name}s"
            atrb[:color] = 5
            super
            def_proc do |ent|
              # Use shell() of top level class
              #  (ie. Dic.new.get(id).shell -> Dic.new.shell(id) )
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
            @disp_dic = @disp_dic.ext_grp
            self
          end
        end
      end

      # Switch View Group
      module View
        deep_include CmdBase
        # atrb should have [:output]
        class Group < CmdBase::Group
          def initialize(spcfg, atrb = Hashx.new)
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

      if __FILE__ == $PROGRAM_NAME
        ConfOpts.new('') do |cfg|
          loc = Index.new(cfg).loc
          loc.add_view
          loc.add_shell
          puts loc.view_dic
        end
      end
    end
  end
end
