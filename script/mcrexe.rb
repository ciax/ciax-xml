#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libmcrexe'
# CIAX-XML Macro Sequencer
module CIAX
  # Macro Exec
  module Mcr
    Conf.new('[proj] [cmd] (par)', options: 'chedlpn') do |cfg|
      atrb = { dev_dic: cfg.opt.top_layer::ExeDic.new(cfg) }
      ent = Index.new(cfg, atrb).add_rem.add_ext.set_cmd(cfg.args)
      Exe.new(ent).seq.play
    end
  end
end
