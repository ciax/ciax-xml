#!/usr/bin/ruby
require 'libhexexe'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    LAYERS << 'hex'
    deep_include(Site)
    # Hex Exe List
    class List
      # atrb must have [:db]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        _store_db(@cfg[:db] ||= Ins::Db.new)
        @sub_list = Wat::List.new(@cfg)
        @sub_list.super_list = self
        @cfg[:hdb] = Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        List.new(cfg, sites: args).run.ext_shell.shell
      end
    end
  end
end
