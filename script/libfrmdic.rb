#!/usr/bin/env ruby
require 'libfrmexe'
require 'libsitedic'
# CIAX-XML
module CIAX
  # Frame Layer
  module Frm
    deep_include(Site)
    # Frame ExeDic module
    class ExeDic
      def initialize(spcfg, atrb = Hashx.new)
        super
        idb = type?(@cfg[:db], Ins::Db)
        @run_list = idb.runlist_dev(@cfg.opt.proper?)
        @db = @cfg[:db] = Dev::Db.new(idb)
      end
    end

    if $PROGRAM_NAME == __FILE__
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        ExeDic.new(cfg, db: Ins::Db.new(cfg.proj))
      end.cui
    end
  end
end
