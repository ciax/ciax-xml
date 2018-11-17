#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrexe'
# CIAX-XML Macro Sequencer
module CIAX
  # Macro Exec
  module Mcr
    ConfOpts.new('[proj] [cmd] (par)', options: 'edlns') do |cfg, args|
      ent = Index.new(cfg).add_rem.add_ext.set_cmd(args)
      mexe = Exe.new(ent)
      cfg[:opt].sh? ? mexe.ext_shell.shell : mexe.seq.play
    end
  end
end
