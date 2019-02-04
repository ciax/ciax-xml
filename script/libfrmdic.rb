#!/usr/bin/env ruby
require 'libfrmexe'
require 'libsitedic'
# CIAX-XML
module CIAX
  # Frame Layer
  module Frm
    deep_include(Site)
    # Frame Dic module
    class Dic
      def initialize(spcfg, atrb = Hashx.new)
        super
        idb = type?(@cfg[:db], Ins::Db)
        ddb = Dev::Db.new(idb.valid_devs)
        _store_db(ddb)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg|
        Dic.new(cfg, db: Ins::Db.new(cfg.proj), sites: cfg.args).shell
      end
    end
  end
end
