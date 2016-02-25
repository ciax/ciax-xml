#!/usr/bin/ruby
require 'libcmdext'
require 'libmcrdb'
# CIAX_XML
module CIAX
  # Macro Layer
  module Mcr
    include Cmd::Remote
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
    }
    # Internal Commands
    module Int
      include Cmd::Remote::Int
      # Internal Group
      class Group < Int::Group
        attr_reader :par
        def initialize(cfg, crnt = {})
          crnt[:caption] = 'Control Macro'
          super
          INTCMD.each do|id, cap|
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
      include Cmd::Remote::Ext
      # Caption change
      class Group < Ext::Group
        def initialize(cfg, crnt = {})
          crnt[:caption] = 'Start Macro'
          super
        end
      end
      # generate [:sequence]
      class Item < Ext::Item
        def gen_entity(opt)
          ent = super
          ent[:sequence] = ent.deep_subst(@cfg[:body])
          ent
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libwatlist'
      cfg = Config.new
      cfg[:dev_list] = Wat::List.new(cfg)
      begin
        dbi = Db.new.get
        cobj = Index.new(cfg, dbi.pick)
        cobj.add_rem
        cobj.rem.def_proc(&:path)
        cobj.rem.add_ext(Ext)
        ent = cobj.set_cmd(ARGV)
        puts ent.path
        puts ent[:sequence]
      rescue InvalidARGS
        Msg.usage('[cmd] (par)')
      end
    end
  end
end
