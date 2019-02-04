#!/usr/bin/env ruby
require 'libhexexe'
# CIAX-XML
module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    deep_include(Site)
    # Hex Exe Dic
    class Dic
      # atrb must have [:db]
      def initialize(spcfg, atrb = Hashx.new)
        super
        idb = type?(@cfg[:db], Ins::Db)
        hdb = @cfg[:hdb] = Db.new
        idb.valid_apps(hdb.disp_dic.valid_keys)
        _store_db(idb)
        ___init_subdic
      end

      private

      def ___init_subdic
        if @cfg[:dev_dic].is_a?(Wat::Dic)
          @sub_dic = @cfg[:dev_dic]
        else
          @sub_dic = Wat::Dic.new(@cfg)
          @sub_dic.super_dic = self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg|
        Dic.new(cfg, db: Ins::Db.new(cfg.proj), sites: cfg.args).shell
      end
    end
  end
end
