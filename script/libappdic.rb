#!/usr/bin/env ruby
require 'libappexe'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    deep_include(Site)
    # Application Dic
    class Dic
      # spcfg must have [:db]
      def initialize(spcfg, atrb = Hashx.new)
        super
        _store_db(type?(@cfg[:db], Ins::Db))
        @sub_dic = Frm::Dic.new(@cfg)
        @sub_dic.super_dic = self
        @cfg[:sdb] = Sym::Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg|
        Dic.new(cfg, db: Ins::Db.new(cfg.proj), sites: cfg.args).shell
      end
    end
  end
end
