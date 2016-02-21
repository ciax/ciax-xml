#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrseq'
# CIAX-XML Macro Sequencer
module CIAX
  module Mcr
    opt = GetOpts.new('cen')
    cfg = Config.new(option: opt)
    wl = Wat::List.new(cfg) # Take App List
    cfg[:dev_list] = wl
    begin
      mobj = Remote::Index.new(cfg, dbi: Db.new.get)
      mobj.add_rem.add_ext(Ext)
      ent = mobj.set_cmd(ARGV)
      seq = Seq.new(ent)
      seq.macro
    rescue InvalidCMD
      opt.usage('[cmd] (par)')
    rescue InvalidID
      opt.usage('[proj] [cmd] (par)')
    end
  end
end
