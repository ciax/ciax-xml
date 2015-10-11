#!/usr/bin/ruby
require 'libremote'
require 'libappdb'

module CIAX
  module App
    include Remote
    # cfg should have [:dbi] and [:stat]
    module Int
      include Remote::Int
      class Group < Int::Group
        def initialize(cfg, attr = {})
          super
          add_item('set', '[key] [val]', def_pars(2))
          add_item('del', '[key,...]', def_pars(1))
        end
      end
    end

    module Ext
      include Remote::Ext
      class Group < Ext::Group; end
      class Item < Ext::Item; end
      class Entity < Ext::Entity
        include Math
        # batch is ary of args(ary)
        def initialize(cfg, attr = {})
          super
          self[:batch] = @body.map do|e1|
            args = []
            enclose("GetCmd(FDB):#{e1.first}", 'Exec(FDB):%s') do
              e1.each do|e2| # //argv
                case e2
                when String
                  args << e2
                when Hash
                  str = e2['val']
                  str = e2['format'] % expr(str) if e2['format']
                  verbose { "Calculated [#{str}]" }
                  args << str
                end
              end
            end
            args
          end.extend(Enumx)
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      OPT.parse('d', 'd' => 'Device Mode')
      id = ARGV.shift
      cfg = Config.new
      dbm = OPT['d'] ? Db : Ins::Db
      begin
        cobj = Index.new(cfg, dbi: dbm.new.get(id))
        cobj.add_rem.def_proc(&:path)
        cobj.rem.add_ext(Ext)
        ent = cobj.set_cmd(ARGV)
        puts ent[:batch].to_s
      rescue InvalidCMD
        Msg.usage("#{id} (-d) [cmd] (par)", 2)
      rescue InvalidID
        Msg.usage('(-d) [id] [cmd] (par)')
      end
    end
  end
end
