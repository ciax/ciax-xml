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
        # Generate [:batch]
        class Form
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
              args.map { |s| ent[:status].subst(s) }
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
        cfg[:status] = Status.new(dbi).cmode(cfg.opt.host)
        # dbi.pick already includes :layer, :command, :version
        rem = Index.new(cfg, dbi.pick).add_rem
        rem.add_int
        rem.add_ext
        ent = rem.set_cmd(cfg.args)
        puts ent.path
        puts 'batch:' + ent[:batch].to_v
      end
    end
  end
end
