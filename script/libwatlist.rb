#!/usr/bin/ruby
require 'libwatexe'

module CIAX
  # Watch Layer
  module Wat
    deep_include(Site)
    # Watch List
    class List
      attr_reader :id
      # super_cfg must have [:db]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        _store_db(@cfg[:db] ||= Ins::Db.new(@id))
        @sub_list = App::List.new(@cfg, sub_atrb)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        List.new(cfg, sites: args).run.ext_shell.shell
      end
    end
  end
end
