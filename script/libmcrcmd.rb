#!/usr/bin/ruby
require 'libcmdext'
require 'libmcrconf'
# CIAX_XML
module CIAX
  Msg.deep_include(Mcr, CmdTree)
  # Macro Layer
  module Mcr
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
          attr_reader :par
          def initialize(cfg, crnt = {})
            crnt[:caption] = 'Control Macro'
            super
            INTCMD.each do |id, cap|
              add_item(id, id.capitalize + ' ' + cap)
            end
          end

          # Shared Parameter
          def ext_par
            @par = Parameter.new('str', '0')
            @cfg[:parameters] = [@par]
            self
          end
        end
      end
      # External Command
      module Ext
        # Caption change
        class Group
          def initialize(cfg, crnt = {})
            crnt[:caption] = 'Start Macro'
            super
          end
        end
        # generate [:sequence]
        class Item
          def gen_entity(opt)
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
        cobj = Index.new(Conf.new(cfg))
        cobj.add_rem.add_ext
        ent = cobj.set_cmd(args)
        puts ent.path
        jj ent[:sequence]
      end
    end
  end
end
