#!/usr/bin/ruby
require 'libhexexe'

module CIAX
  # Ascii Hex Layer for OLD CIAX
  module Hex
    # Hex Exe List
    class List < Site::List
      # cfg must have [:db]
      def initialize(cfg, top_list = nil)
        super(cfg, top_list || self, Wat::List)
        store_db(@cfg[:db] ||= Ins::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('ceh:lts')
      cfg = List::Config.new
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
