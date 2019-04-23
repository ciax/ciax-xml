#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libmcrexe'
# CIAX-XML Macro Sequencer
module CIAX
  # Macro Exec
  module Mcr
    Opt::Conf.new('[proj] [cmd] (par)', options: 'edln') do |cfg|
      ent = Index.new(cfg, Atrb.new(cfg)).add_rem.add_ext.set_cmd(cfg.args)
      mexe = Exe.new(ent)
      cfg.args.empty? ? mexe.run.shell : (exit mexe.seq.play.to_i)
    end
  end
end
