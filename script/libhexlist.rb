#!/usr/bin/ruby
require 'libhexexe'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    # Hex Exe List
    class List < Site::List
      # cfg must have [:db]
      def initialize(cfg, atrb = {})
        super
        init_sub(Wat::List)
        store_db(@cfg[:db] ||= Ins::Db.new)
        @cfg[:hdb] = Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id]', 'ceh:lts') do |opt|
        cfg = Config.new(option: opt, site: ARGV.shift)
        List.new(cfg).ext_shell.shell
      end
    end
  end
end
