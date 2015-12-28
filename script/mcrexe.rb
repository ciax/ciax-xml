#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrseq'
# CIAX-XML Macro Sequencer
module CIAX
  module Mcr
    OPT.parse('cenm')
    cfg = Config.new
    wl = Wat::List.new(cfg) # Take App List
    cfg[:dev_list] = wl
    begin
      mobj = Remote::Index.new(cfg, dbi: Db.new.get)
      mobj.add_rem.add_ext(Ext)
      ent = mobj.set_cmd(ARGV)
      seq = Seq.new(ent)
      seq.macro
    rescue InvalidCMD
      OPT.usage('[cmd] (par)')
    rescue InvalidID
      OPT.usage('[proj] [cmd] (par)')
    end
  end
end
