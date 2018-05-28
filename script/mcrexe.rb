#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libseq'
# CIAX-XML Macro Sequencer
module CIAX
  # Macro Exec
  module Mcr
    ConfOpts.new('[proj] [cmd] (par)', options: 'edln') do |cfg, args|
      mobj = Index.new(Conf.new(cfg))
      mobj.add_rem.add_ext
      ent = mobj.set_cmd(args)
      Sequencer.new(ent).upd_sites.play
    end
  end
end
