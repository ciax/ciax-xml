#!/usr/bin/ruby
require 'libcmdext'
require 'libappdb'
# CIAX-XML Command module
module CIAX
  # Application Mode
  module App
    deep_include(CmdTree)
    # Remote Domain
    module Remote
      # Internal Commands
      module Int
        # Internal Command Group
        class Group
          # cfg should have [:dbi] and [:stat]
          def initialize(cfg, atrb = Hashx.new)
            super
            init_item_file_io
            add_item('set', '[key] [val]').def_pars(2)
            add_item('del', '[key,...]').def_pars(1)
          end
        end
      end
      # External Command
      module Ext
        # Generate [:batch]
        class Item
          # Ext entity
          include Math

          private

          # batch is ary of args(ary)
          def _gen_entity(opt)
            ent = super
            ent[:batch] = ent.deep_subst(@cfg[:body]).map do |e1|
              args = []
              enclose("GetCmd(FDB):#{e1.first}", 'Exec(FDB):%s') do
                ___get_args(e1, args)
              end
              args
            end.extend(Enumx)
            ent
          end

          def ___get_args(e1, args)
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
