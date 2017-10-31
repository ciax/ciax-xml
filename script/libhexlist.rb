#!/usr/bin/ruby
require 'libhexexe'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    deep_include(Site)
    # Hex Exe List
    class List
      # cfg must have [:db]
      def initialize(cfg, atrb = Hashx.new)
        super
        store_db(@cfg[:db] ||= Ins::Db.new)
        @sub_list = Wat::List.new(@cfg)
        @cfg[:hdb] = Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        List.new(cfg, sites: args).ext_shell.shell
      end
    end
  end
end
