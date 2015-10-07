#!/usr/bin/ruby
require 'libremote'
require 'libmcrdb'

module CIAX
  module Mcr
    include Remote
    module Int
      include Remote::Int
      class Group < Int::Group
        attr_reader :par
        def initialize(cfg, crnt = {})
          super
          @par = { type: 'str', list: [], default: '0' }
          @cfg[:parameters] = [@par]
          {
            'start' => 'Sequence',
            'exec' => 'Command',
            'skip' => 'Macro',
            'drop' => ' Macro',
            'suppress' => 'and Memorize',
            'force' => 'Proceed',
            'pass' => 'Execution',
            'ok' => 'for the message',
            'retry' => 'Checking'
          }.each {|id, cap|
            add_item(id, id.capitalize + ' ' + cap)
          }
        end
      end
    end

    module Ext
      include Remote::Ext
      class Group < Ext::Group; end
      class Item < Ext::Item; end
      class Entity < Ext::Entity
        attr_reader :sequence
        def initialize(cfg, crnt = {})
          super
          # @cfg[:body] expansion
          sequence = Arrayx.new
          @body.each {|elem|
            case elem['type']
            when 'select'
              hash = { 'type' => 'mcr' }
              sel = elem['select']
              val = type?(self[:dev_list], App::List).getstat(elem)
              hash['args'] = sel[val] || sel['*']
              sequence << hash
            else
              sequence << elem
            end
          }
          @sequence = self[:sequence] = sequence
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libwatexe'
      OPT.parse
      cfg = Config.new
      cfg[:dev_list] = Wat::List.new(cfg).sub_list
      begin
        cobj = Index.new(cfg, { dbi: Db.new.get(PROJ) })
        cobj.add_rem
        cobj.rem.def_proc(&:path)
        cobj.rem.add_ext(Ext)
        ent = cobj.set_cmd(ARGV)
        puts ent.path
        puts ent.sequence.to_v
      rescue InvalidCMD
        OPT.usage('[id] [cmd] (par)')
      end
    end
  end
end
