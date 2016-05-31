#!/usr/bin/ruby
require 'libhexexe'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    # Hex Exe List
    class List < Site::List
      # cfg must have [:db]
      def initialize(cfg, atrb = Hashx.new)
        super
        @sub_list = Wat::List.new(cfg)
        store_db(@cfg[:db] ||= Ins::Db.new)
        @cfg[:hdb] = Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        List.new(cfg, sites: args).ext_shell.shell
      end
    end
  end
end
