#!/usr/bin/ruby
require 'libcmdext'
require 'libappdb'
# CIAX-XML Command module
module CIAX
  # Application Mode
  module App
    include Cmd::Remote
    # cfg should have [:dbi] and [:stat]
    module Int
      include Cmd::Remote::Int
      # Internal Command
      class Group < Int::Group
        def initialize(cfg, attr = {})
          super
          add_item('set', '[key] [val]', def_pars(2))
          add_item('del', '[key,...]', def_pars(1))
        end
      end
    end
    # External Command
    module Ext
      include Cmd::Remote::Ext
      class Group < Ext::Group; end
      # Generate [:batch]
      class Item < Ext::Item
        # Ext entity
        include Math
        # batch is ary of args(ary)
        def gen_entity(opt)
          ent = super
          ent[:batch] = ent.deep_subst(@cfg[:body]).map do|e1|
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
          e1.each do|e2| # //argv
            case e2
            when String
              args << e2
            when Hash
              str = e2[:val]
              str = e2[:format] % expr(str) if e2[:format]
              verbose { "Calculated [#{str}]" }
              args << str
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      OPT.parse('i', i: 'Instance Mode')
      id = ARGV.shift
      cfg = Config.new
      begin
        dbi = (OPT[:i] ? Ins::Db : Db).new.get(id)
        cobj = Index.new(cfg, dbi.pick)
        cobj.add_rem.def_proc(&:path)
        cobj.rem.add_ext(Ext)
        ent = cobj.set_cmd(ARGV)
        puts ent[:batch].to_s
      rescue InvalidCMD
        OPT.usage("#{id} (-i) [cmd] (par)")
      rescue InvalidID
        OPT.usage('(-i) [id] [cmd] (par)')
      end
    end
  end
end
