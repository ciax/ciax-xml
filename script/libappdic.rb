#!/usr/bin/env ruby
require 'libappexe'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    deep_include(Site)
    # Application ExeDic
    class ExeDic
      # spcfg must have [:db]
      def initialize(spcfg, atrb = Hashx.new)
        super
        _store_db(type?(@cfg[:db], Ins::Db)) do |db|
          db.valid_ins.trues
        end
        @sub_dic = Frm::ExeDic.new(@cfg)
        @sub_dic.super_dic = self
        @cfg[:sdb] = Sym::Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehl') do |cfg|
        eobj = ExeDic.new(cfg, db: Ins::Db.new(cfg.proj)).get(cfg.args.shift)
        if cfg.args.empty?
          eobj.shell
        else
          puts [eobj.exe(cfg.args), eobj.stat]
        end
      end
    end
  end
end
