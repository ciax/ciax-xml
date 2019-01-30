#!/usr/bin/ruby
require 'libcmdext'
require 'libmcrconf'
# CIAX_XML
module CIAX
  # Macro Layer
  module Mcr
    deep_include(CmdTree)
    # Mcr Command Top
    class Index < CmdTree::Index
      def initialize(cfg, atrb = Hashx.new)
        proj = cfg[:proj] ||= (ENV['PROJ'] || cfg[:args].shift)
        cfg[:dbi] = Db.new.get(proj)
        cfg[:sv_stat] = Prompt.new(proj, cfg[:opt])
        super
      end
    end

    module Local
      # Local Domain
      class Domain
        def add_page(atrb = Hashx.new)
          add_grp('Page', atrb)
        end
      end

      # Switch Page Group
      module Page
        deep_include CmdBase
        # Page Group
        class Group < CmdBase::Group
          def initialize(super_cfg, atrb = Hashx.new)
            atrb.update(caption: 'Switch Pages', color: 5)
            super
            add_dummy('0', 'List page')
            add_dummy('[1-n]', 'Switch Pages')
            add_item('last', 'Get last item [n]').pars.add_num('1')
            add_item('cl', 'Clean list')
          end
        end
      end
    end

    # Remote Commands
    module Remote
      INTCMD = {
        'exec' => 'Command',
        'pass' => 'Macro',
        'enter' => 'Sub Macro',
        'drop' => ' Macro',
        'suppress' => 'and Memorize',
        'force' => 'Proceed',
        'skip' => 'Execution',
        'ok' => 'for the message',
        'retry' => 'Checking'
      }.freeze
      # Internal Commands
      module Int
        # Internal Group
        class Group
          def initialize(super_cfg, crnt = {})
            crnt[:caption] = 'Control Macro'
            super
            INTCMD.each do |id, cap|
              add_item(id, id.capitalize + ' ' + cap)
            end
          end
        end
      end
      # External Command
      module Ext
        # Caption change
        class Group
          def initialize(super_cfg, crnt = {})
            crnt.update(caption: 'Start Macro', sites: super_cfg[:dbi][:sites])
            super
          end
        end
        # generate [:sequence]
        class Item
          private

          def _gen_entity(opt)
            ent = super
            ent[:sequence] = ent.deep_subst(@cfg[:body])
            ent
          end
        end
      end

      # System commands
      module Sys
        # System group
        class Group
          def initialize(dom_cfg, atrb = Hashx.new)
            super
            add_item('nonstop', 'Mode')
            add_item('interactive', 'Mode')
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libwatdic'
      ConfOpts.new('[cmd] (par)', options: 'j') do |cfg, args|
        ent = Index.new(cfg).add_rem.add_ext.set_cmd(args)
        puts ent.path
        jj ent[:sequence]
      end
    end
  end
end
