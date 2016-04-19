#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libseq'
# CIAX-XML Macro Sequencer
module CIAX
  # Macro Exec
  module Mcr
    ConfOpts.new('[proj] [cmd] (par)', 'cen') do |cfg, args|
      wl = Wat::List.new(cfg) # Take App List
      cfg[:dev_list] = wl
      mobj = Index.new(cfg, dbi: Db.new.get)
      mobj.add_rem.add_ext(Ext)
      ent = mobj.set_cmd(args)
      seq = Sequencer.new(ent)
      seq.macro
    end
  end
end
