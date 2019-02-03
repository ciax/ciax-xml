#!/usr/bin/env ruby
require 'libwatexe'
# CIAX-XML
module CIAX
  # Watch Layer
  module Wat
    deep_include(Site)
    # Watch Dic
    class Dic
      attr_reader :id
      # spcfg must have [:db]
      def initialize(spcfg, atrb = Hashx.new)
        super
        _store_db(@cfg[:db] ||= Ins::Db.new(@id))
        @sub_dic = App::Dic.new(@cfg)
        @sub_dic.super_dic = self
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
      ConfOpts.new('[id]', options: 'cehls') do |cfg|
        Dic.new(cfg, sites: cfg.args).shell
      end
    end
  end
end
