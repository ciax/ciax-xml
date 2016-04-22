#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libseq'
# CIAX-XML Macro Sequencer
module CIAX
  # Macro Exec
  module Mcr
    ConfOpts.new('[proj] [cmd] (par)', 'cen') do |cfg, args|
      mobj = Cmd::Index.new(Conf.new(cfg))
      mobj.add_rem.add_ext(Ext)
      ent = mobj.set_cmd(args)
      Sequencer.new(ent).upd.macro
    end
  end
end
