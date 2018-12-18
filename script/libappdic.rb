#!/usr/bin/ruby
require 'libappexe'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    deep_include(Site)
    # Application List
    class List
      # super_cfg must have [:db]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        _store_db(@cfg[:db] ||= Ins::Db.new(@id))
        @sub_list = Frm::List.new(@cfg)
        @sub_list.super_list = self
        @cfg[:sdb] = Sym::Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        List.new(cfg, sites: args).shell
      end
    end
  end
  @top_layer = App
end
