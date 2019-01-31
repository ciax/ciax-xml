#!/usr/bin/ruby
require 'libfrmexe'
require 'libsitedic'
# CIAX-XML
module CIAX
  # Frame Layer
  module Frm
    deep_include(Site)
    # Frame Dic module
    class Dic
      def initialize(super_cfg, atrb = Hashx.new)
        super
        idb = (@cfg[:db] ||= Ins::Db.new)
        ddb = Dev::Db.new(idb.valid_devs)
        _store_db(ddb)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg|
        Dic.new(cfg, sites: cfg.args).shell
      end
    end
  end
end
