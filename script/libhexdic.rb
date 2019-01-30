#!/usr/bin/ruby
require 'libhexexe'
# CIAX-XML
module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    deep_include(Site)
    # Hex Exe Dic
    class Dic
      # atrb must have [:db]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        idb = (@cfg[:db] ||= Ins::Db.new)
        hdb = @cfg[:hdb] = Db.new
        idb.valid_apps(hdb.disp_dic.valid_keys)
        _store_db(idb)
        @sub_dic = Wat::Dic.new(@cfg)
        @sub_dic.super_dic = self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        Dic.new(cfg, sites: args).shell
      end
    end
  end
end
