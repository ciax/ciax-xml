#!/usr/bin/ruby
require 'libextcmd'
require 'libmcrdb'
# CIAX_XML
module CIAX
  # Macro Layer
  module Mcr
    include Remote
    INTCMD = {
      'exec' => 'Command',
      'skip' => 'Macro',
      'drop' => ' Macro',
      'suppress' => 'and Memorize',
      'force' => 'Proceed',
      'pass' => 'Execution',
      'ok' => 'for the message',
      'retry' => 'Checking'
    }
    # Internal Commands
    module Int
      include Remote::Int
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
      include Remote::Ext
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
          opt[:sequence] = Arrayx.new(@cfg[:body])
          super
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libwatlist'
      cfg = Config.new
      cfg[:dev_list] = Wat::List.new(cfg)
      begin
        cobj = Index.new(cfg, dbi: Db.new.get)
        cobj.add_rem
        cobj.rem.def_proc(&:path)
        cobj.rem.add_ext(Ext)
        ent = cobj.set_cmd(ARGV)
        puts ent.path
        puts ent[:sequence].to_v
      rescue InvalidID
        OPT.usage('[cmd] (par)')
      end
    end
  end
end
