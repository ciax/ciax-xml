#!/usr/bin/ruby
require 'libremote'
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
      class Group < Ext::Group
        def initialize(cfg, crnt = {})
          crnt[:caption] = 'Start Macro'
          super
        end
      end
      class Item < Ext::Item; end
      # External Entity
      class Entity < Ext::Entity
        def initialize(cfg, crnt = {})
          super
          # @cfg[:body] expansion
          seq = self[:sequence] = Arrayx.new
          init_sel(seq)
        end

        private

        def init_sel(seq)
          @body.each do|e|
            case e[:type]
            when 'select'
              sel = e[:select]
              wat = type?(self[:dev_list], Wat::List).get(e[:site])
              val = wat.sub.stat[e[:var]]
              seq << { type: 'mcr', args: sel[val] || sel['*'] }
            else
              seq << e
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libwatexe'
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
