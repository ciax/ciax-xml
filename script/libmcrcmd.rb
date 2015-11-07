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
          super
          @par = { type: 'str', list: [], default: '0' }
          @cfg[:parameters] = [@par]
          INTCMD.each do|id, cap|
            add_item(id, id.capitalize + ' ' + cap)
          end
        end
      end
    end
    # External Command
    module Ext
      include Remote::Ext
      class Group < Ext::Group; end
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
          @body.each do|elem|
            case elem['type']
            when 'select'
              sel = elem['select']
              val = type?(self[:dev_list], App::List).getstat(elem)
              seq << { 'type' => 'mcr', 'args' => sel[val] || sel['*'] }
            else
              seq << elem
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libwatexe'
      cfg = Config.new
      cfg[:dev_list] = Wat::List.new(cfg).sub_list
      begin
        cobj = Index.new(cfg, dbi: Db.new.get(PROJ))
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
