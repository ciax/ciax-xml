#!/usr/bin/env ruby
require 'libhexexe'
# CIAX-XML
module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    deep_include(Site)
    # Hex Exe ExeDic
    class ExeDic
      # atrb must have [:db]
      def initialize(spcfg, atrb = Hashx.new)
        super
        _store_db(type?(@cfg[:db], Ins::Db))
        _init_subdic(Wat)
        hdb = @cfg[:hdb] = Db.new
        @db.valid_apps(hdb.disp_dic.valid_keys)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        ExeDic.new(cfg, db: Ins::Db.new(cfg.proj))
      end.cui
    end
  end
end
