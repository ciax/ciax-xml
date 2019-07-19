#!/usr/bin/env ruby
require 'libwatexe'
# CIAX-XML
module CIAX
  # Watch Layer
  module Wat
    deep_include(Site)
    # Watch ExeDic
    class ExeDic
      # spcfg must have [:db]
      def initialize(spcfg, atrb = Hashx.new)
        super
        @db = type?(@cfg[:db], Ins::Db)
        @run_list = @db.runlist_ins
        _init_subdic(App)
      end

      def init_sites
        __each_site(@cfg[:sites]) if @cfg.key?(:sites)
      end

      def interrupt(sites)
        msg("\nInterrupt Issued to running devices #{sites}", 3)
        __each_site(sites) { |obj| obj.exe(['interrupt'], 'user') }
      end

      private

      def __each_site(ary)
        ary.each do |site|
          obj = get(site)
          yield obj if defined? yield
        end
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        ExeDic.new(cfg, db: Ins::Db.new(cfg.proj))
      end.cui
    end
  end
end
