#!/usr/bin/ruby
require 'libcmdext'
require 'libappdb'
# CIAX-XML Command module
module CIAX
  # Application Mode
  module App
    include Cmd
    class Index < Index; end
    # Local Domain
    module Local
      include Cmd::Local
      class Domain < Domain; end
      # Sh Group
      module Sh
        include Cmd::Local::Sh
        class Group < Group; end
      end
      # Jump Group
      module Jump
        include Cmd::Local::Jump
        class Group < Group; end
        class Item < Item; end
        class Entity < Entity; end
      end
      # View Group
      module View
        include Cmd::Local::View
        class Group < Group; end
        class Item < Item; end
        class Entity < Entity; end
      end
    end
    # Remote Domain
    module Remote
      include Cmd::Remote
      class Domain < Domain; end
      # System Commands
      module Sys
        include Cmd::Remote::Sys
        class Group < Group; end
        class Item < Item; end
        class Entity < Entity; end
      end
      # Internal Commands
      module Int
        include Cmd::Remote::Int
        # Internal Command Group
        class Group < Group
          # cfg should have [:dbi] and [:stat]
          def initialize(cfg, atrb = Hashx.new)
            super
            init_item_file_io
            add_item('set', '[key] [val]', def_pars(2))
            add_item('del', '[key,...]', def_pars(1))
          end
        end
        class Item < Item; end
        class Entity < Entity; end
      end
      # External Command
      module Ext
        include Cmd::Remote::Ext
        class Group < Group; end
        # Generate [:batch]
        class Item < Item
          # Ext entity
          include Math
          # batch is ary of args(ary)
          def gen_entity(opt)
            ent = super
            ent[:batch] = ent.deep_subst(@cfg[:body]).map do |e1|
              args = []
              enclose("GetCmd(FDB):#{e1.first}", 'Exec(FDB):%s') do
                _get_args(e1, args)
              end
              args
            end.extend(Enumx)
            ent
          end

          private

          def _get_args(e1, args)
            e1.each do |e2| # //argv
              if e2.is_a? String
                args << e2
              elsif e2.is_a? Hash
                str = e2[:val]
                str = e2[:format] % expr(str) if e2[:format]
                verbose { "Calculated [#{str}]" }
                args << str
              end
            end
          end
        end
        class Entity < Entity; end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      ConfOpts.new('[id] [cmd] (par)', options: 'i') do |cfg, args|
        dbi = (cfg[:opt][:i] ? Ins::Db : Db).new.get(args.shift)
        # dbi.pick already includes :layer, :command, :version
        cobj = Index.new(cfg, dbi.pick)
        cobj.add_rem.add_ext
        ent = cobj.set_cmd(args)
        puts ent[:batch].to_s
      end
    end
  end
end
