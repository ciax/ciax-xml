#!/usr/bin/ruby
require 'libcmdext'
require 'libmcrconf'
# CIAX_XML
module CIAX
  # Macro Layer
  module Mcr
    deep_include(CmdTree)
    module Local
      # Local Domain
      class Domain
        def add_page(atrb = Hashx.new)
          add_grp('Page', atrb)
        end
      end

      # Switch View Group
      module View
        # View Group
        class Group
          def initialize(super_cfg, atrb = Hashx.new)
            super
            add_item('dig', 'Show more Submacros')
            add_item('hide', 'Hide Submacros')
          end
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
            pars = add_item('last', 'Get last item [n]').pars_num(1)
            pars.first[:default] = nil
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

          def dev_list
            opt = @cfg[:opt]
            site_cfg = @cfg.gen(self)
            site_cfg.update(proj: @cfg[:id], opt: opt.sub_opt)
            dev_layer = opt[:x] ? Hex : Wat
            @cfg[:dev_list] = dev_layer::List.new(site_cfg)
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
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libwatlist'
      ConfOpts.new('[cmd] (par)', options: 'j') do |cfg, args|
        cobj = Index.new(cfg)
        cobj.add_rem.add_ext
        ent = cobj.set_cmd(args)
        puts ent.path
        jj ent[:sequence]
      end
    end
  end
end
