#!/usr/bin/env ruby
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
          def initialize(spcfg, atrb = Hashx.new)
            super
            _init_form_int
          end
        end
      end
      # External Command
      module Ext
        # External Group
        class Group
          def initialize(spcfg, atrb = Hashx.new)
            super
            add_form('upd', 'Update')
          end
        end
        # Generate [:batch]
        class Form
          # Ext entity
          include Math

          private

          # Substitution order
          #  1. Parameter($1,$2..)
          #  2. Status   (${id1}, ${id2}..)

          def _gen_entity(opt)
            ent = super
            # batch is ary of args(ary)
            ent[:batch] = ent.deep_subst_par(@cfg[:body] || []).map do |e1|
              args = []
              enclose("GetCmd(FDB):#{e1.first}", 'Exec(FDB):%s') do
                ___get_args(e1, args)
              end
              args.map { |s| @cfg[:stat_pool].subst(s) }
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
      require 'libappstat'
      Opt::Conf.new('[id] [cmd] (par)', options: 'a') do |cfg|
        dbi = (cfg.opt[:a] ? Db : Ins::Db).new.get(cfg.args.shift)
        cfg[:stat_pool] = StatPool.new(Status.new(dbi).cmode(cfg.opt.host))
        # dbi.pick already includes :layer, :command, :version
        rem = Index.new(cfg, dbi.pick).add_rem
        rem.add_int
        rem.add_ext
        ent = rem.set_cmd(cfg.args)
        puts ent[:status]
        puts ent.path
        puts 'batch:' + ent[:batch].to_v if ent.key?(:batch)
      end
    end
  end
end
