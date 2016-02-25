#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrseq'
# CIAX-XML Macro Sequencer
module CIAX
  module Mcr
    opt = GetOpts.new
    begin
      cfg = Config.new(option: opt.parse('cen'))
      wl = Wat::List.new(cfg) # Take App List
      cfg[:dev_list] = wl
      mobj = Index.new(cfg, dbi: Db.new.get)
      mobj.add_rem.add_ext(Ext)
      ent = mobj.set_cmd(ARGV)
      seq = Seq.new(ent)
      seq.macro
    rescue InvalidCMD
      opt.usage('[cmd] (par)')
    rescue InvalidARGS
      opt.usage('[proj] [cmd] (par)')
    end
  end
end
