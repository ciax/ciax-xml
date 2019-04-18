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
        _store_db(Dev::Db.new) { idb.valid_devs.trues }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehli') do |cfg|
        eobj = ExeDic.new(cfg, db: Ins::Db.new(cfg.proj)).get(cfg.args.shift)
        if cfg.opt.sh?
          eobj.shell
        else
          puts [eobj.exe(cfg.args), eobj.stat]
        end
      end
    end
  end
end
